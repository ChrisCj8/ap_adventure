local NODE = {}

NODE.SubNodes = true

function NODE:InitNode()
    return {
        type = "or",
        nodes = {}
    }
end

return NODE