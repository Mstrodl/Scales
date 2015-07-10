#!/bin/bash
#
# Minecraft Installer
# Written for Ubuntu Sysems
#
# ./minecraft_install.sh -b /home/ -u username [-p plugin -s sponge_version -f forge_version -v vanilla_version]

# Allows enough time for PufferPanel to get the Feed
sleep 5

username=root
base="/home/"
plugin="cauldron"
spongeVersion=""
forgeVersion="1.7.10-10.13.3.1408"
vanillaVersion="1.7.10"

while getopts ":b:u:s:f:p:v:" opt; do
    case "$opt" in
    b)
        base=$OPTARG
        ;;
    u)
        username=$OPTARG
        ;;
    s)
        spongeVersion=$OPTARG
        ;;
    f)
        forgeVersion=$OPTARG
        ;;
    p)
        plugin=$OPTARG
        ;;
    v)
        vanillaVersion=$OPTARG
        ;;
    esac
done

if [ "$username" == "root" ]; then

    echo "WARNING: Invalid Username Supplied."
    exit 1

fi;

if [ ! -d "${base}${username}/public" ]; then
    echo "The home directory for the user (${base}${username}/public) does not exist on the system."
    exit 1
fi;

cd ${base}${username}/public

if [ "$plugin" == "spigot" ]; then

    # We will ignore -r for this since there is no easy way to do a specific version of Spigot.
    # To install a specific version the user should manually build and upload files.
    echo 'Downloading BuildTools for Spigot'
    echo "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
    curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

    git config --global --unset core.autocrlf
    java -jar BuildTools.jar

    echo 'Removing BuildTools Files and Folders...'
    mv spigot*.jar ../server.jar
    rm -rf *
    mv ../server.jar server.jar

elif [[ "$plugin" == "forge" || $plugin == "sponge-forge" ]]; then

    echo "Downloading Forge Version ${forgeVersion}";
    echo "http://files.minecraftforge.net/maven/net/minecraftforge/forge/${forgeVersion}/forge-${forgeVersion}-installer.jar"
    curl -o MinecraftForgeInstaller.jar http://files.minecraftforge.net/maven/net/minecraftforge/forge/${forgeVersion}/forge-${forgeVersion}-installer.jar

    java -jar MinecraftForgeInstaller.jar --installServer

    mv forge-${forgeVersion}-universal.jar server.jar
    rm -f MinecraftForgeInstaller.jar

    # Install Sponge Now
    if [ "$plugin" == "sponge-forge" ]; then

        mkdir mods
        cd mods

        echo "Installing Sponge Version ${spongeVersion}"
        echo "http://repo.spongepowered.org/maven/org/spongepowered/sponge/${spongeVersion}/sponge-${spongeVersion}.jar"
        curl -o sponge-${spongeVersion}.jar http://repo.spongepowered.org/maven/org/spongepowered/sponge/${spongeVersion}/sponge-${spongeVersion}.jar

    fi

elif [ "$plugin" == "sponge" ]; then

    echo 'Sponge Standalone is not currently suported in this version.';

elif [[ "$plugin" == "vanilla" ]]; then

    echo "Downloading Remote File..."
    echo "https://s3.amazonaws.com/Minecraft.Download/versions/${vanillaVersion}/minecraft_server.${vanillaVersion}.jar"
    curl -o server.jar https://s3.amazonaws.com/Minecraft.Download/versions/${vanillaVersion}/minecraft_server.${vanillaVersion}.jar

fi

elif [ "$plugin" == "cauldron" ]; then
    echo "Downloading Remote File..."
    echo "https://prok.pw/repo/pw/prok/KCauldron/${cauldronVersion}/KCauldron-${cauldronVersion}-installer.jar"
    curl -o /tmp/KCauldron-${cauldronVersion}-installer.jar https://prok.pw/repo/pw/prok/KCauldron/1.7.10-1420.108/KCauldron-${cauldronVersion}-installer.jar
    echo "Running KCauldron-${cauldronVersion}-installer.jar..."
    echo $(java -jar /tmp/KCauldron-${cauldronVersion}-installer.jar --installServer) > /var/log/cauldron-install.log
    statCode="$?"
    if [ "$statCode" == "0" ]; then
        echo "Successfully installed!"
        echo "Deleting KCauldron-${cauldronVersion}-installer.jar..."
        rm -f /tmp/KCauldron-${cauldronVersion}-installer.jar
        echo "Deleting cauldron-install.log..."
        rm -f /var/log/caudron-install.log
    fi
    elif [ "$statCode" != "0" ]; then
        echo "'java -jar /tmp/KCauldron-${cauldronVersion}-installer.jar --installServer' failed with exit code '$statCode' (Do you have internet?) Try running installer again and/or checking the log file (Located at '/var/log/cauldron-install.log')"
        exit $statCode
    fi
fi
echo 'Fixing permissions for downloaded files...'
chown -R ${username}:scalesuser *

echo 'Exiting Installer'
exit 0
