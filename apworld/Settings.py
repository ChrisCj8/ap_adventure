import settings
import typing

class GMADVSettings(settings.Group):
    class GModPath(settings.UserFolderPath):
        description = "The Location of your GarrysMod Folder"
        

    gmodpath: GModPath = None