local NODE = {}

NODE.SubNodes = true

function NODE:InitNode()
    return {
        type = "and",
        nodes = {}
    }
end

return NODE