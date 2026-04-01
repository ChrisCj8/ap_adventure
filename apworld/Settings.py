import settings
import typing

class APADVSettings(settings.Group):
    class GModPath(settings.UserFolderPath):
        description = "The Location of your GarrysMod Folder"
        

    gmodpath: GModPath = None