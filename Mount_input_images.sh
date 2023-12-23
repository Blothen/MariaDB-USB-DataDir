#!/usr/bin/env bash
#SOURCE ENV AND SCRIPTS
source ./config.env # Source Config
#Ciarán Johnson 2023
#Photo Experience

function Mount_input {
    sudo mkdir -p $input_images_source
    sudo rm -rf $input_images_dir
    sudo ln -s $input_images_source $input_images_dir
    sudo chmod +777 $input_images_source
}

Mount_input ||exit 0


