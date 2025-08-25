#!/bin/bash
clear
echo "Welcome to the SNT Item Adder!"
echo "Here you can add tags, trails, and sounds"
echo

echo "First you need to provide MySQL username"
read -p "USERNAME: " sqlUser
echo

read -p "What kind of item did you want to add? " usrChoice
echo

usrChoiceLower=$(echo $usrChoice | awk '{print tolower($0)}')

if [ "${usrChoiceLower:0:2}" == "ta" ]
then

    read -p "How many tags did you want to add? " numTags
    echo

    for ((i=1; i<=$numTags; i++))
    do

        read -p "Item ID (eg. tag_alin): " itemId
        read -p "Tag Name (eg. Alien): " tagName
        read -p "Tag Display (eg. [Alien]): " tagDisplay
        read -p "Tag Color (eg. {deepblue}): " tagColor
        read -p "Tag Owner (Leave blank for store, Steam3 ID otherwise): " tagOwner
        read -p "Tag Price (Leave blank for 0): " tagPrice
        echo

        if [ "$tagOwner" == "" ]
        then
            tagOwner="STORE"
        fi

        if [ "$tagPrice" == "" ]
        then
            tagPrice=0
        else
            tagPrice=$((tagPrice))
        fi

        mysql -u $sqlUser -p sntdb -e "INSERT INTO storetags VALUES (\"$itemId\", \"$tagName\", \"$tagDisplay\", \"$tagColor\", \"$tagOwner\", $tagPrice)"

    done

elif [ "${usrChoiceLower:0:2}" == "tr" ]
then

    read -p "How many trails did you want to add? " numTrails
    echo

    for (( i=1; i<=$numTrails; i++ ))
    do

        read -p "Item ID (eg. trl_weed): " itemId
        read -p "Trail Name (eg. Weed): " trailName
        read -p "Trail FileName (eg. trail_weed): " trailFile
        read -p "Trail Owner (Leave blank for store, Steam3 ID otherwise): " trailOwner
        read -p "Trail Price (Leave blank for 0): " trailPrice
        echo

        if [ "$trailOwner" == "" ]
        then
            trailOwner="STORE"
        fi

        if [ "$trailPrice" == "" ]
        then
            trailPrice=0
        else
            trailPrice=$((trailPrice))
        fi

        mysql -u $sqlUser -p sntdb -e "INSERT INTO storetrails VALUES (\"$itemId\", \"$trailName\", \"materials/snt_trails/$trailFile.vtf\", \"materials/snt_trails/$trailFile.vmt\", \"$trailOwner\", $trailPrice)"

    done

elif [ "${usrChoiceLower:0:2}" == "so" ]
then

    read -p "How many sounds did you want to add? " numSounds
    echo

    for ((i=1; i<=$numSounds; i++))
    do

        read -p "Item ID (eg. snd_yarr): " itemId
        read -p "Sound Name (eg. Yarr): " soundName
        read -p "Soundfile (eg. ypp_yarr): " soundFile
        read -p "Sound Cooldown (Leave blank for 0.1): " soundCooldown
        read -p "Trail Owner (Leave blank for store, Steam3 ID otherwise): " soundOwner
        read -p "Trail Price (Leave blank for 0): " soundPrice
        echo

        if [ "$soundCooldown" == "" ]
        then
            soundCooldown=0.1
        else
            soundCooldown=$((soundCooldown))
        fi

        if [ "$soundOwner" == "" ]
        then
            soundOwner="STORE"
        fi

        if [ "$soundPrice" == "" ]
        then
            soundPrice=0
        else
            soundPrice=$((soundPrice))
        fi

        mysql -u $sqlUser -p sntdb -e "INSERT INTO storetrails VALUES (\"$itemId\", \"$trailName\", \"materials/snt_trails/$trailFile.vtf\", \"materials/snt_trails/$trailFile.vmt\", \"$trailOwner\", $trailPrice)"

    done

fi

exit 0