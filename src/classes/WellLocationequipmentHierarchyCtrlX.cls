/*----------------------------------------------------------------------------------------------------
Author     : Shreyas Dhond
Company    : Husky Energy
Description: A controller class for displaying Equipment Hierarchy for Well
             Location
Test Class : WellLocationequipmentNodesCtrlXTest
History    :
            09.29.15 ssd Initial Revision                                         
------------------------------------------------------------------------------------------------------*/
public with sharing class WellLocationequipmentHierarchyCtrlX {

    //Private Variables
    private Id wellLocationId;
    private List<Equipment__c> equipmentList;
    private List<EquipmentNode> equipmentNodes;
    private List<EquipmentNode> sortedNodeList;

    
    //Extended Constructor
    public WellLocationequipmentHierarchyCtrlX(ApexPages.StandardController stdController) {
        wellLocationId = stdController.getId();
    }

    public List<EquipmentNode> getEquipmentHierarchy() {
        if(sortedNodeList == null || sortedNodeList.isEmpty()) {
            equipmentList = [Select Id, Name, Superior_Equipment__c,
                                    Description_of_Equipment__c, Manufacturer__c,
                                    Model_Number__c, Manufacturer_Serial_No__c,
                                    Tag_Number__c
                            From Equipment__c
                            Where Location__c =: wellLocationId];

            sortedNodeList = new List<EquipmentNode>();
            for(Equipment__c equipment : equipmentList) {
                if(equipment.Superior_Equipment__c == null) {
                    EquipmentNode node = new EquipmentNode(0, 0, equipment, true, null);
                    sortedNodeList.add(node);
                    sortedNodeList.addAll(getChildren(node));
                }
            }
        }

        return sortedNodeList;
    }

    public List<EquipmentNode> getEquipmentHierarchyVisible() {

        List<EquipmentNode> resultNodeList = new List<EquipmentNode>();

        if(sortedNodeList == null || sortedNodeList.isEmpty()) {
            resultNodeList = getEquipmentHierarchy();
        }

        for(EquipmentNode node : sortedNodeList) {
            if(!node.getIsParentClosed()) {
                resultNodeList.add(node);
            }
        }       
        return resultNodeList;
    }


    public void toggleNodeState() {
        Id nodeId = ApexPages.currentPage().getParameters().get('nodeId');
        getNode(nodeId).toggleState();
    }

    ///////////////////////
    // Utility Functions //
    ///////////////////////

    //Get Node From NodeId
    private EquipmentNode getNode(Id nodeId) {
        for(EquipmentNode node : sortedNodeList) {
            if(node.getId() == nodeId) {
                return node;
            }
        }
        return null;
    }

    private List<EquipmentNode> getChildren(EquipmentNode pNode) {
        List<EquipmentNode> nodes = new List<EquipmentNode>();
        for(Equipment__c equipment : equipmentList) {
            if(equipment.Superior_Equipment__c == pNode.equipment.Id) {
                pNode.hasChildren = true;
                EquipmentNode childNode = new EquipmentNode(0, pNode.level+1, equipment, true, pNode);
                nodes.add(childNode);
                nodes.addAll(getChildren(childNode));
            }
        }
        return nodes;
    }

    public with sharing class EquipmentNode {
        public Integer index;
        public Integer level;
        public Equipment__c equipment;
        public Boolean closed;
        public EquipmentNode parent;
        public Boolean hasChildren;
        public Map<Id, Boolean> ancestorClosedMap;

        public Id getId() { return equipment.Id; }
        public Equipment__c getEquipment() { return equipment;}
        public Integer getLevel() { return level; }
        public Boolean getClosed() { return closed; }
        public Id getParentId() { return (parent == null) ? null : parent.getId(); }
        public Boolean getHasChildren() { return hasChildren; }
        public Boolean getIsParentClosed() { 
            /*return (parent == null) ? false : parent.getClosed();*/

            if(parent != null) {
                EquipmentNode ancestorNode = parent;
                while(ancestorNode != null) {
                    if(ancestorNode.getClosed() == true) {
                        return true;
                    }
                    ancestorNode = ancestorNode.parent;
                }
            }

            return false;
        }

        public Boolean toggleState() {
            this.closed = !this.closed;
            return this.closed;
        }

        public EquipmentNode(Integer pIndex, Integer pLevel, Equipment__c pEquipment, Boolean pClosed, EquipmentNode pParent) {
            this.index = pIndex;
            this.level = pLevel;
            this.equipment = pEquipment;
            this.closed = pClosed;
            this.parent = pParent;
            hasChildren = false;
        }
    }
}