@isTest
private class WellLocationEquipmentHierarchyCtrlXTest {
	
	static Testmethod void testEquipmentHierarchy() {
		Location__c testLocation = LocationTestData.createLocation();
		List<Equipment__c> testEquipmentHierarchy = EquipmentTestData.createEquipmentHierarchy(testLocation);

		WellLocationequipmentHierarchyCtrlX wellLocationHierarchyCtrl = new WellLocationequipmentHierarchyCtrlX(
			new ApexPages.StandardController(testLocation));

		List<WellLocationequipmentHierarchyCtrlX.EquipmentNode> equipmentHierarchyResult = wellLocationHierarchyCtrl.getEquipmentHierarchy();

		//Test Hierarchy Structure
		System.assertEquals(equipmentHierarchyResult.size(), 5);
		for(Integer i=0; i < 5; i++) {
			System.debug('Superior Equipment: ' +testEquipmentHierarchy[i].Superior_Equipment__c);
			System.assertEquals(equipmentHierarchyResult[i].getId(), testEquipmentHierarchy[i].Id);
			System.assertEquals(equipmentHierarchyResult[i].getLevel(), i);
			if(i == 0) {
				//Top Level tests
				System.assertEquals(equipmentHierarchyResult[i].getParentId(), null);
				System.assertEquals(equipmentHierarchyResult[i].getIsParentClosed(), false);
				System.assertEquals(equipmentHierarchyResult[i].getHasChildren(), true);
			} else if (i == 4) {
				System.assertEquals(equipmentHierarchyResult[i].getParentId(), equipmentHierarchyResult[i-1].getId());
				System.assertEquals(equipmentHierarchyResult[i].getIsParentClosed(), true);
				System.assertEquals(equipmentHierarchyResult[i].getHasChildren(), false);
			} else {
				System.assertEquals(equipmentHierarchyResult[i].getParentId(), equipmentHierarchyResult[i-1].getId());
				System.assertEquals(equipmentHierarchyResult[i].getIsParentClosed(), true);
				System.assertEquals(equipmentHierarchyResult[i].getHasChildren(), true);
			}
		}

		//Test Hierarchy Behaviour
		ApexPages.currentPage().getParameters().put('nodeId', testEquipmentHierarchy[0].Id);
		wellLocationHierarchyCtrl.toggleNodeState();
		equipmentHierarchyResult = wellLocationHierarchyCtrl.getEquipmentHierarchy();
		System.assertEquals(equipmentHierarchyResult[1].getIsParentClosed(), equipmentHierarchyResult[0].getClosed());
	}
}