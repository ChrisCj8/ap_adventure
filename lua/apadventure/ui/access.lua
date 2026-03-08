local function ImageButton(parent,image) 
    local btn = vgui.Create("DImageButton",parent)
    btn:SetImage(image)
    btn:SetSize(16,16)
    return btn
end

return function(parent,targetheight)

    local container = vgui.Create("DCollapsibleCategory",parent)
    container:SetLabel("#apadventure.ui.accessedit.label")
    container.TargetHeight = targetheight or 300
    
    local basetbl
    local basekey

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
                basetbl[basekey] = tbl
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
                basetbl[basekey] = tbl
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

    local nodepnl = vgui.Create("DPanel",container)
    local nodepnloldlayout = nodepnl.PerformLayout
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

    function delbtn:DoClick()
        local curnode = accesstree:GetSelectedItem()
        if !IsValid(curnode) then return end
        local parentnode = curnode:GetParentNode()
        if parentnode:IsRootNode() then
            curnode:Remove()
            basetbl[basekey] = nil
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
        nodepnl.PerformLayout = nodepnloldlayout
        nodepnl:Clear()
    end

    function cutbtn:DoClick()
        copybtn:DoClick()
        delbtn:DoClick()
    end



    local oldlayout = container.PerformLayout
    function container:PerformLayout(w,h)
        if self:GetExpanded() then h = self.TargetHeight end
        oldlayout(self,w,h)
        nodeselect:SetSize(w-115,25)

        addbtn:SetPos(w-107,29)
        delbtn:SetPos(w-87,29)

        cutbtn:SetPos(w-62,29)
        copybtn:SetPos(w-42,29)
        pastebtn:SetPos(w-22,29)

        local treewidth = 200
        local nodepnlwidth = w-210
        local nodepnlx = 210

        if nodepnlwidth < treewidth then
            treewidth = (w-10)/2
            nodepnlx = treewidth + 10
            nodepnlwidth = w - nodepnlx
        end

        accesstree:SetSize(treewidth,h-60)

        nodepnl:SetSize(nodepnlwidth,h-60)
        nodepnl:SetPos(nodepnlx,55)
    end

    function container:LoadTbl(tbl,key)

        basetbl = tbl
        basekey = key or "access"
        local access = tbl[basekey]

        accesstree:Clear()

        if access and next(access) then
            local basenode = accesstree:AddNode(access.type,nodetypes[access.type].Icon or "icon16/bullet_black.png")
            basenode.tbl = access
            if access.nodes then
                addnodes(basenode,access.nodes)
                basenode:ExpandRecurse(true)
            end
            accesstree:OnNodeSelected(basenode)
        else
            nodepnl.PerformLayout = nodepnloldlayout
            nodepnl:Clear()
        end
    end

    return container

end