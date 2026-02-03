import time
import requests
import mysql.connector
import json

# Holds stuff like qualities, attributes, unusual ids
SCHEMA_OVERVIEW_URL = "https://api.steampowered.com/IEconItems_440/GetSchemaOverview/v1/"

# Holds actual items
ITEM_SCHEMA_URL= "https://api.steampowered.com/IEconItems_440/GetSchemaItems/v1/"

gS_webAPIKey = ""
gS_language = ""

quasardb = mysql.connector.connect(
    host='localhost',
    user='quasar',
    password='quasar',
    database='quasar',
    auth_plugin='mysql_native_password'
)

lst_invalidIndexes = {
    1133, # Powerup Strength
    1134, # Powerup Haste
    1135, # Powerup Regen
    1136, # Powerup Resist
    1137, # Powerup Vampire
    1138, # Powerup Reflect
    1139, # Powerup Precision
    1140, # Powerup Agility
    1154, # Powerup Knockout
    1159, # Powerup King
    1160, # Powerup Plague
    1161, # Powerup Supernova
    5639, # Summer Claim Check
    5718, # Stocking Stuffer
    5086, # Summer Starter Kit
    5087, # Summer Adventure Pack
    5606, # Barley-Melted Capacitor
    5607, # Pile of Ash
    5626, # Pile of Curses
    5741, # Bread Box
    190,  # 190 - 212 Upgradeable [STOCK WEAPON]
    191,
    192,
    193,
    194,
    195,
    196,
    197,
    198,
    199,
    200,
    201,
    202,
    203,
    204,
    205,
    206,
    207,
    208,
    209,
    210,
    211,
    212,
    5849, # 5849 - 5858 && 5860 Keyless Cosmetic Crates
    5850, 
    5851,
    5852,
    5853,
    5854,
    5855,
    5856,
    5857,
    5858,
    5860,
    8938, # Glitched Circuit Board
    1155, # Weapon_Passtime_Gun
    5772, # Halloween gift Cauldron
    5773, # Halloween gift cauldron
}

lst_invalidClasses = {
    "tool",
    "supply_crate",
    "bundle",
    "map_token",
    "class_token",
    "slot_token",
    "craft_item"
}

lst_invalidNames = {
    "concealedkiller_",
    "craftsmann_",
    "teufort_",
    "powerhouse_",
    "harvest_",
    "pyroland_",
    "gentlemanne_",
    "warbird_",
    "Powerup"
}

lst_invalidItemTypes = {
    "Tournament Medal",
    "Community Medal",
    "Unlocked Crate",
    "Gift",
    "Supply Crate",
    "CheatDetector",
    "Usable Item",
    "Package"
}

gH_request = None

def IsValidItem(item):
    b_hasInvalidName = False
    for name in lst_invalidNames:
        if name in item["name"]:
            b_hasInvalidName = True
            break

    if (#Item classes
        item["item_class"]      in lst_invalidClasses   or

        # Types of items
        item["item_type_name"]  in lst_invalidItemTypes or

        # specific indexes.
        item["defindex"]        in lst_invalidIndexes   or

        # invalid item name stuff
        b_hasInvalidName):
            return False
    else:
        return True
    
def InsertItems(itemJson):
    print("New item insert cycle started")
    c = quasardb.cursor()
    for index in range(0, len(itemJson["result"]["items"])):
        item = itemJson["result"]["items"][index]

        if not (IsValidItem(item)):
            continue

        #print(str(index)+ " [" + str(item["defindex"]) + "] " + item["name"] + ": (" + item["item_name"] + ")")

        c.execute(
            "INSERT INTO `quasar`.`tf_items` (`id`, `name`, `classname`, `slot`, `min_level`, `max_level`) " \
            "VALUES (%s, %s, %s, %s, %s, %s) ON DUPLICATE KEY " \
            "UPDATE `id`=`id`, `name`=`name`, `classname`=`classname`, `slot`=`slot`, `min_level`=`min_level`, `max_level`=`max_level`;",
            [
                item["defindex"],
                item["item_name"],
                item["item_class"],
                item["item_slot"],
                item["min_ilevel"],
                item["max_ilevel"]
            ]
        )
        quasardb.commit()
        
        i_class = -1;
        if ("used_by_classes" in item):
            for users in item["used_by_classes"]:
                match users:
                    case "Scout":
                        i_class = 1
                    case "Soldier":
                        i_class = 2
                    case "Pyro":
                        i_class = 3
                    case "Demoman":
                        i_class = 4
                    case "Heavy":
                        i_class = 5
                    case "Engineer":
                        i_class = 6
                    case "Medic":
                        i_class = 7
                    case "Sniper":
                        i_class = 8
                    case "Spy":    
                        i_class = 9
                    case _:
                        i_class = 1
                
                c.execute(
                    "INSERT INTO `quasar`.`tf_items_classes` (`item_id`, `class`) " \
                    "VALUES (%s, %s) ON DUPLICATE KEY " \
                    "UPDATE `item_id`=`item_id`, `class`=`class`;",
                    [
                        item["defindex"],
                        i_class
                    ]
                )
                quasardb.commit()
        else:
            for tfclass in range(1, 10):
                c.execute(
                    "INSERT INTO `quasar`.`tf_itemsclasses` (`item_id`, `class`) " \
                    "VALUES (%s, %s) ON DUPLICATE KEY " \
                    "UPDATE `item_id`=`item_id`, `class`=`class`;",
                    [
                        item["defindex"],
                        tfclass
                    ]
                )
                quasardb.commit()
        
        if "attributes" in item:
            for attrib in item["attributes"]:
                c.execute("" \
                "INSERT INTO `quasar`.`tf_itemsattributes` (`item_id`, `attribute_classname`, `attribute_value`)" \
                "VALUES (%s, %s, %s) ON DUPLICATE KEY " \
                "UPDATE `item_id`=`item_id`, `attribute_classname`=`attribute_classname`, `attribute_value`=`attribute_value`",
                [
                    item["defindex"],
                    attrib["class"],
                    attrib["value"]
                ])
                quasardb.commit()

        time.sleep(1/60)
    
    c.close();
    if ("next" in itemJson["result"]):
        return itemJson["result"]["next"]
    else:
        return -1


def main():
    print("Welcome to the quasar itemdef updater")

    c = quasardb.cursor()

    print("In order to access the Steam WebAPI, you need to enter your API key.")
    print("YOUR WEBAPI KEY IS ONLY USED TO ACCESS THE TF2 ITEM SCHEMA!\nTHIS PROGRAM DOES NOT SAVE OR SEND YOUR API KEY TO ANY WEBSITE BUT STEAM!\n")

    gS_webAPIKey = input("Please enter your Steam WebAPI key: ");
    gS_language = input ("Please enter the language you want results in: ");

    dict_overviewPayload = {
        'key': gS_webAPIKey,
        'language': gS_language
    }
    req_schemaOverview = requests.get(SCHEMA_OVERVIEW_URL, dict_overviewPayload)
    
    dict_schemaPayload = {
        'key': gS_webAPIKey,
        'language': gS_language,
        'next': None
    }
    req_itemSchema = requests.get(ITEM_SCHEMA_URL, dict_schemaPayload)

    if (req_schemaOverview.status_code != 200):
        print("------------------\nUnable to reach Steam WebAPI!")
        print("\nCould not access GetSchemaOverview!")
        print("Status: " + str(req_schemaOverview.status_code) + " Reason: " + req_schemaOverview.reason)
        req_schemaOverview.close()
        req_itemSchema.close()
        return
    
    dict_overview = req_schemaOverview.json()
    dict_schema = req_itemSchema.json()
    print("Got the JSONs for GetSchemaOverview and GetSchemaItems")

    # Grab all the stuff in the item overview
    dict_result = dict_overview["result"]
    dict_attributes = dict_result["attributes"]
    dict_unusuals = dict_result["attribute_controlled_attached_particles"]
    dict_qualities = dict_result["qualities"]
    dict_qualityNames = dict_result["qualityNames"]

    print("Currently grabbing item attributes")
    s_descString = ""
    # Handle all of the TF Item Attributes
    for attrib in dict_attributes:
        if ("description_string" not in attrib):
            s_descString = "NONE"
        else:
            s_descString = attrib["description_string"]

        c.execute(
            "INSERT INTO `quasar`.`tf_attributes` (`id`, `name`, `classname`, `description`) " \
            "VALUES (%s, %s, %s, %s) ON DUPLICATE KEY " \
            "UPDATE `id`=`id`, `name`=`name`, `classname`=`classname`;",
            [
                attrib["defindex"], 
                attrib["name"], 
                attrib["attribute_class"], 
                s_descString
            ])
        quasardb.commit()

    # Handle all of the TF Unusual Particles
    print("Getting tf particle effects")
    s_unusType = "COSMETIC"
    for unus in dict_unusuals:
        if ("utaunt" in unus["system"]):
            s_unusType = "TAUNT"

        c.execute(
            "INSERT INTO `quasar`.`tf_particles` (`id`, `name`, `system_name`, `type`) " \
            "VALUES (%s, %s, %s, %s) ON DUPLICATE KEY " \
            "UPDATE `id`=`id`, `name`=`name`, `system_name`=`system_name`, `type`=`type`;",
            [
                unus["id"], 
                unus["name"], 
                unus["system"],
                s_unusType
            ])
        quasardb.commit()

    # Handle all of the TF Item Qualities
    print("Getting tf item qualities")
    for qual in dict_qualities:
        c.execute(
            "INSERT INTO `quasar`.`tf_qualities` (`id`, `name`) " \
            "VALUES (%s, %s) ON DUPLICATE KEY " \
            "UPDATE `id`=`id`, `name`=`name`;",
            [
                dict_qualities[qual],
                dict_qualityNames[qual],
            ])
        quasardb.commit()
    
    req_schemaOverview.close()
    del dict_result, dict_attributes, dict_unusuals, dict_qualities

    if (req_itemSchema.status_code != 200):
        print("------------------\nUnable to reach Steam WebAPI!")
        print("\nCould not access GetSchemaItems!")
        print("Status: " + str(req_itemSchema.status_code) + " Reason: " + req_itemSchema.reason)
        req_schemaOverview.close()
        req_itemSchema.close()
        return

    print("Getting tf items")
    i_nextItem = InsertItems(dict_schema)

    while "next" in dict_schema["result"]:
        dict_payload = {
            'key':      gS_webAPIKey,
            'language': gS_language,
            'start':     i_nextItem
        }

        gH_request = requests.get(ITEM_SCHEMA_URL, dict_payload)

        if (gH_request.status_code != 200):
            print("------------------\nUnable to reach Steam WebAPI!")
            print("\nCould not access GetSchemaItems!")
            print("Status: " + str(gH_request.status_code) + " Reason: " + gH_request.reason)
            gH_request.close()
            return

        dict_schema = gH_request.json()
        i_nextItem = InsertItems(dict_schema)
        gH_request.close();

    del dict_schemaPayload, dict_overviewPayload, dict_schema
    req_itemSchema.close()
    c.close()
    quasardb.close()
    print("Finished updating Quasar item schema!")

if __name__ == "__main__":
    main()