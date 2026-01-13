local function ImageButton(parent,image) 
    local btn = vgui.Create("DImageButton",parent)
    btn:SetImage(image)
    btn:SetSize(16,16)
    return btn
end

return function(parent)

    local container = vgui.Create("DCollapsibleCategory",parent)
    container:SetLabel("#apadventure.ui.accessedit.label")
    
    local curcon = false 

    local nodetypes = {}

    for k,v in ipairs(file.Find("apadventure/ui/accessnodes/*.lua","lcl")) do
        local name = string.sub(v,0,-5)
        nodetypes[name] = include("apadventure/ui/accessnodes/"..v)
    end

    local accesstree = vgui.Create("DTree",container)
    accesstree:SetPos(5,55)

    local nodeselect = vgui.Create("DComboBox",container)
    nodeselect:SetPos(5,25)

    for k,v in pairs(nodetypes) do
        nodeselect:AddChoice(k,k)
    end

    local addnodes

    function addnodes(base,tbl)
        for k,v in ipairs(tbl) do
            local node = base:AddNode(v.type,nodetypes[v.type].Icon or "icon16/bullet_black.png")
            node.tbl = v
            node.tblkey = k
            if v.nodes then
                addnodes(node,v.nodes)
            end
        end
    end

    local addbtn = ImageButton(container,"icon16/add.png")
    function addbtn:DoClick()
        local curnode = accesstree:GetSelectedItem()
        local nodename, nodedata = nodeselect:GetSelected()
        if !nodedata then return end
        local nodetype = nodetypes[nodedata]
        if !IsValid(curnode) then
            local rootnode = accesstree:Root()
            if !rootnode or rootnode:GetChildNodeCount() > 0 then return else
                local node = accesstree:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
                local tbl = nodetype.InitNode()
                node.tbl = tbl
                curcon.access = tbl
            end
        elseif nodetypes[curnode.tbl.type].SubNodes then
            local node = curnode:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
            local tbl = nodetype.InitNode()
            local newkey =  #curnode.tbl.nodes+1
            curnode.tbl.nodes[newkey] = tbl
            node.tbl = tbl
            node.tblkey = newkey
            curnode:ExpandRecurse(true)
        end
    end

    local delbtn = ImageButton(container,"icon16/delete.png")
    function delbtn:DoClick()
        local curnode = accesstree:GetSelectedItem()
        if !IsValid(curnode) then return end
        local parentnode = curnode:GetParentNode()
        if parentnode:IsRootNode() then
            curnode:Remove()
            curcon.access = nil
        else
            local parenttbl = parentnode.tbl
            local newtbl = {}
            local curnodekey = curnode.tblkey
            i = 1
            for k,v in ipairs(parenttbl.nodes) do
                if k != curnodekey then
                    newtbl[i] = v 
                    i = i + 1
                end
            end
            parentnode.tbl.nodes = newtbl
            for k,v in ipairs(parentnode:GetChildNodes()) do
                v:Remove()
            end
            addnodes(parentnode,newtbl)
            parentnode:ExpandRecurse(true)
        end
    end

    local cutbtn = ImageButton(container,"icon16/cut.png")
    local copybtn = ImageButton(container,"icon16/page_white_copy.png")
    local pastebtn = ImageButton(container,"icon16/paste_plain.png")

    function copybtn:DoClick()
        local curnode = accesstree:GetSelectedItem()
        if IsValid(curnode) then
            local tocopy = table.Copy(curnode.tbl)
            apAdventure.AccessNodeClipboard = tocopy
        end
    end

    function pastebtn:DoClick()
        local curnode = accesstree:GetSelectedItem()
        local nodedata = apAdventure.AccessNodeClipboard
        if !nodedata then return end
        local nodename = nodedata.type
        if !IsValid(curnode) then
            local rootnode = accesstree:Root()
            if !rootnode or rootnode:GetChildNodeCount() > 0 then return else
                local node = accesstree:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
                local tbl = table.Copy(nodedata)
                node.tbl = tbl
                curcon.access = tbl
                if tbl.nodes and next(tbl.nodes) then
                    addnodes(node,tbl.nodes)
                    rootnode:ExpandRecurse(true)
                end
            end
        elseif nodetypes[curnode.tbl.type].SubNodes then
            local node = curnode:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
            local tbl = table.Copy(nodedata)
            local newkey =  #curnode.tbl.nodes+1
            curnode.tbl.nodes[newkey] = tbl
            node.tbl = tbl
            node.tblkey = newkey
            if tbl.nodes and next(tbl.nodes) then
                addnodes(node,tbl.nodes)
            end
            curnode:ExpandRecurse(true)
        end
    end

    function cutbtn:DoClick()
        copybtn:DoClick()
        delbtn:DoClick()
    end

    local nodepnl = vgui.Create("DPanel",container)
    nodepnl:SetPos(210,55)

    function accesstree:OnNodeSelected(node)
        nodepnl.PerformLayout = nil
        nodepnl:Clear()
        nodepnl.nodetbl = node.tbl
        local pnlfunc = nodetypes[node.tbl.type].Panel

        if isfunction(pnlfunc) then
            pnlfunc(nodepnl)
        end
    end

    local oldlayout = container.PerformLayout
    function container:PerformLayout(w,h)
        oldlayout(self,w,h)
        nodeselect:SetSize(w-115,25)

        addbtn:SetPos(w-107,29)
        delbtn:SetPos(w-87,29)

        cutbtn:SetPos(w-62,29)
        copybtn:SetPos(w-42,29)
        pastebtn:SetPos(w-22,29)

        accesstree:SetSize(200,h-60)

        nodepnl:SetSize(w-210,h-60)
    end

    function container:LoadTbl(tbl)

        curcon = tbl
        local access = tbl.access

        accesstree:Clear()

        if access then
            PrintTable(access)
            local basenode = accesstree:AddNode(access.type,nodetypes[access.type].Icon or "icon16/bullet_black.png")
            basenode.tbl = access
            if access.nodes then
                addnodes(basenode,access.nodes)
                basenode:ExpandRecurse(true)
            end
        end
    end

    return container

end