#!/bin/bash
# Discord Linux Audio Assistant
# Version 0.1.0
#
# https://github.com/stairman06/discord-linux-audio
# 
# Credit to edisionnano's guide at https://github.com/edisionnano/Screenshare-with-audio-on-Discord-wit


# UI Settings
UI_TITLE="Discord Linux Audio Assistant"

# PulseAudio Settings
PA_OUTPUT=$(pactl info | sed -n -e 's/^.*Default Sink: //p')

PA_FAKESINK_NAME="dlaa-fakesink"
PA_FAKESINK_DESCRIPTION="DLAA Discord Screenshare Audio"
PA_FAKESINK_ID="?"

PA_VIRTMIC_NAME="dlaa-virtmic"
PA_VIRTMIC_DESCRIPTION="dlaa-virtmic"

PA_LOOPBACK_DESCRIPTION="DLAA-Loopback"

### PulseAudio Controls

# Sinks are stored in indexed array
# e.g. PA_SINKINPUTS_NAMES[0] describes PA_SINKINPUTS_IDS[0]
PA_SINKINPUTS_IDS=()
PA_SINKINPUTS_NAMES=()
PA_SINKINPUTS_SINKS=()

# Load all available sink inputs
loadSinkInputs() {
    i=-1

    # Set to 1 when we need to skip to the next sink
    skip=0

    while read -r line; do

        # Check if we're declaring a new sink
        if [[ $line == "Sink Input"* ]]; then
            # If so, grab the ID
            sinkId="${line/"Sink Input #"/}"

            ((i++))

            skip=0

            # Assign the ID
            PA_SINKINPUTS_IDS[i]="$sinkId"
        fi

        # Check if the sink doesn't have a client
        # Sinks without a client are not real (e.g. loopback),
        # so they need to be ignored
        if [[ $line == "Client: n/a" ]]; then
            # The ID has already been added, so we need to remove it
            unset 'PA_SINKINPUTS_IDS[i]'

            # Go back
            ((i--))
            # Skip to next sink
            skip=1
        fi

        # Make sure we aren't skipping this sink
        if [[ $skip == 0 ]]; then
            # Grab the assigned sink
            if [[ $line == "Sink: "* ]]; then
                assignedSink="${line/"Sink: "}"
                PA_SINKINPUTS_SINKS[i]="$assignedSink"
            fi

            # Grab media.name
            if [[ $line == "media.name"* ]]; then
                mediaName="${line/"media.name = \""}"
                mediaName="${mediaName::-1}"

                PA_SINKINPUTS_NAMES[i]="$mediaName"
            fi

            # Grab application.name
            if [[ $line == "application.name"* ]]; then
                applicationName="${line/"application.name = \""/}"
                applicationName="${applicationName::-1}"

                PA_SINKINPUTS_NAMES[i]+=" ($applicationName)"
            fi
        fi
    done <<< "$(pactl list sink-inputs)"
}

# Finds fakesink's ID
findFakesinkId() {
    # ID of the current sink
    currentId="?"
    found=0

    while read -r line; do
        # If this line is declaring a new sink
        if [[ $line == "Sink "* ]]; then
            currentId="${line/"Sink #"/}"
        fi

        # Check if this is the fakesink
        if [[ $line == "Name: $PA_FAKESINK_NAME" ]]; then
            # End the loop since we've found it
            found=1
            break
        fi
    done <<< "$(pactl list sinks)"

    if [[ $found == 1 ]]; then
        PA_FAKESINK_ID=$currentId
    fi
}

# Create the fakesink if needed
createFakesink() {
    # Check if the sinks already contains the fakesink
    if [[ "$(pactl list short sinks)" != *"$PA_FAKESINK_NAME"* ]]; then
        # Create the sink
        pactl load-module module-null-sink sink_name="$PA_FAKESINK_NAME"

        # Update the description
        pacmd update-sink-proplist "$PA_FAKESINK_NAME" device.description="\"$PA_FAKESINK_DESCRIPTION\""
    fi
}


# Loopback the fakesink to default output
setLoopback() {
    # Check if the loopback exists
    if [[ "$(pactl list sink-inputs)" != *"$PA_LOOPBACK_DESCRIPTION"* ]]; then
        pactl load-module module-loopback source="$PA_FAKESINK_NAME.monitor" sink="$PA_OUTPUT" sink_input_properties=media.name="$PA_LOOPBACK_DESCRIPTION"
    fi
}

# Create the virtual microphone for discord
setVirtMic() {
    # Check if the virtmic exists
    if [[ "$(pactl list short sources)" != *"$PA_VIRTMIC_NAME"* ]]; then
        if pactl info|grep -w "PipeWire">/dev/null; then
            nohup pw-loopback --capture-props="node.target=$PA_FAKESINK_NAME" --playback-props="media.class=Audio/Source node.name=$PA_VIRTMIC_NAME node.description=\"$PA_VIRTMIC_NAME\"" &
        else
            pactl load-module module-remap-source master="$PA_FAKESINK_NAME.monitor" source_name="$PA_VIRTMIC_NAME"
            pacmd update-source-proplist "$PA_VIRTMIC_NAME" device.description="\"$PA_VIRTMIC_DESCRIPTION\""
        fi
    fi
}

### UI

## UI Tools

# Show a message box
uiMessage() {
    dialog --backtitle "$UI_TITLE" --msgbox "$@" 0 0
}

# Show an infobox
uiInfo() {
    dialog --backtitle "$UI_TITLE" --infobox "$@" 0 0
}

## UI Screens

# Main welcome screen
uiMain() {
    selection=$(dialog --backtitle "$UI_TITLE" --title "Main menu" --menu \
        "Select an option" \
        0 0 0 \
        0 "Choose programs to stream" \
        1 "Debug menu" 2>&1 > /dev/tty)
    
    case "$selection" in
        "0")
            uiStreamWindow
            ;;
        "1")
            uiDebug
            ;;
        *)
            exit
            ;;
    esac

    # Go back to main window after finishing a selection
    uiMain
}

# Configure and setup stuff
uiCheckSetup() {
    uiInfo "Setting up Discord Linux Audio Assistant..."
    loadSinkInputs
    createFakesink
    findFakesinkId
    setLoopback
    setVirtMic
}

# Stream a window
uiStreamWindow() {
    loadSinkInputs
    findFakesinkId

    if [[ "${#PA_SINKINPUTS_NAMES}" == 0 ]]; then
        uiMessage "No audio-outputting programs found. Start a program and come back to this screen"
        return
    fi

    dialogArgs=()

    for i in "${!PA_SINKINPUTS_NAMES[@]}"; do
        prepend=""

        # Check if this input is broadcasting to the fakesink
        if [[ "${PA_SINKINPUTS_SINKS[i]}" == "$PA_FAKESINK_ID" ]]; then
            # Prepend "[active]" if so
            prepend="[active] "
        fi

        dialogArgs+=("$i")
        dialogArgs+=("$prepend${PA_SINKINPUTS_NAMES[i]}")
    done

    program=$(dialog --backtitle "$UI_TITLE" --title "Choose streaming programs" --menu \
        "Select programs to stream" \
        0 0 0 \
        "${dialogArgs[@]}" 2>&1 > /dev/tty)
    
    # Check if no program was selected, if so exit
    if [[ "$program" == "" ]]; then
        return
    fi

    # Grab the sinkinput ID of the program
    programSinkInput="${PA_SINKINPUTS_IDS[program]}"

    # Check if it's already active

    if [[ "${PA_SINKINPUTS_SINKS[program]}" != "$PA_FAKESINK_ID" ]]; then
        # It's not being mixed already

        createFakesink

        # Move sinkinput
        pactl move-sink-input "$programSinkInput" "$PA_FAKESINK_NAME"

        setLoopback

        setVirtMic 
    else
        # Otherwise the program is already being mixed, so reset it
        pactl move-sink-input "$programSinkInput" "$PA_OUTPUT"
    fi    

    uiStreamWindow    
}

debugResetSinkInputs() {
    loadSinkInputs
    for id in "${PA_SINKINPUTS_IDS[@]}"; do
        pactl move-sink-input "$id" "$PA_OUTPUT"
    done
}

debugRemoveFakesink() {
    pactl unload-module module-null-sink
}

debugRemoveVirtmic() {
    pkill -9 pw-loopback
    pactl unload-module module-remap-source
}

debugRemoveLoopback() {
    pactl unload-module module-loopback
}

# Debugger UI
uiDebug() {
    selection=$(dialog --backtitle "$UI_TITLE" --title "Debug menu (ADVANCED)" --menu \
        "Select an option" \
        0 0 0 \
        0 "Kill pulseaudio" \
        1 "Create fakesink" \
        2 "Set loopback" \
        3 "Set virtmic" \
        4 "Reset all sink inputs" \
        5 "Remove fakesink" \
        6 "Remove virtmic" \
        7 "Remove loopback" \
        8 "Remove everything" \
        2>&1 > /dev/tty)
    
    case "$selection" in
        # Kill pulseaudio
        0)
            pulseaudio -k
            ;;
        # Create fakesink
        1)
            createFakesink
            ;;
        # Set loopback
        2)  
            setLoopback
            ;;
        # Set virtmic
        3)
            setVirtmic
            ;;
        # Reset all sink inputs
        4)
            debugResetSinkInputs
            ;;
        # Remove fakesink
        5)
            debugRemoveFakesink
            ;;
        # Remove virtmic
        6)
            debugRemoveVirtmic
            ;;
        # Remove loopback
        7)
            debugRemoveLoopback
            ;;
        # Remove everything
        8) 
            debugResetSinkInputs
            debugRemoveFakesink
            debugRemoveVirtmic
            debugRemoveLoopback
            ;;
        *)
            uiMain
            ;;
    esac

    uiDebug
}

uiCheckSetup
uiMain