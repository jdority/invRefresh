/// J. Dority  7-3-19
// Example REST call out to external inventory system.    List is used to compare against B2B Commerce 
// which will be updated to reflect current inventory.
// 
global with sharing class ckz_POCinvRefresh {
    
    private static String updateFromExtInv() {
        
        String ProductItem = null;  	//record id of Product
        String Name = null;         	//name of inventory record i.e. U61 Warehouse
        String Status = null;			//In Stock, Back Order, Out of Stock, etc.
        Decimal QtyAvailable = null;	//Quantity on Hand
        
        ccrz.ccLog.log('ckz_', 'updateFromExtInv() begin');
        
        //Named Credential for External System
        String url = 'callout:HerokuExtData/salesforce$ccrz__e_productinventoryitem__c';
        
        // Instantiate a new http object
        Http h = new Http();
        
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(url);
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        System.debug('response:--> ' + res.getBody());
        
        // Deserialize the JSON string into collections of primitive data types.
        Map < String,Object > MyMap = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
        system.debug('resultsMap-->' + MyMap);
        
        List<Object> valueList = (List<Object>)MyMap.get('value');
        
        
        integer i = 0;
        integer cnt = valueList.size();
        if(!valueList.isEmpty()) {
            //loop through external inventory list and apply changes to B2B Commerce
            for (i = 0; i < cnt; i++ )   {
                Object obj = valueList.get(i);
                
                Map<String, Object> objMap = (Map<String, Object>)obj;
                
                Name = (String)objMap.get('name'); //case sensitive (external source)
                QtyAvailable = (Decimal)objMap.get('ccrz__qtyavailable__c');
                Status = (String)objMap.get('ccrz__status__c'); 
                ProductItem = (String)objMap.get('ccrz__productitem__c');
                
                // Fetch B2B Commerce Product Inventory record
                // product inventory object does not appear to have a primary key, so combining name and productitem
                List<ccrz__e_productinventoryitem__c> prodInvList = 
                    [SELECT id, name, ccrz__ProductItem__c, ccrz__QtyAvailable__c, ccrz__Status__c 
                     FROM ccrz__e_productinventoryitem__c
                     WHERE ccrz__ProductItem__c = :ProductItem];
                     
                List<ccrz__e_productinventoryitem__c> prodInvUpd = new List<ccrz__e_productinventoryitem__c>();
                
                // If not found in B2B Commerce, insert new inventory record - ProductItem ID is stored in external system
                if(prodInvList.isEmpty()) {   
                    
                    prodInvUpd.add(new ccrz__e_productinventoryitem__c(
                        Id = null,
                        Name = Name,
                        ccrz__ProductItem__c = ProductItem,
                        ccrz__Status__c = Status,
                        ccrz__QtyAvailable__c = QtyAvailable));

                    insert prodInvUpd; 
                    system.debug('Insert new inventory item-->' + prodInvUpd[0].ccrz__ProductItem__c);
                    ccrz.ccLog.log('ckz_POCOProdInvCtl', 'Insert: ' + ProductItem);}
                else
                {
                    if (prodInvList[0].ccrz__QtyAvailable__c != QtyAvailable ||
                        prodInvList[0].ccrz__Status__c != Status) {
                            
                            prodInvList[0].ccrz__QtyAvailable__c = QtyAvailable;
                            prodInvList[0].ccrz__Status__c = Status;
                            prodInvUpd.add(prodInvList[0]);
                            
                            // If Qty or Status are diffrent, update Product Inventory
                            update prodInvUpd;
                            ccrz.ccLog.log('ckz_POCOProdInvCtl', 'Updated: ' + QtyAvailable);
                        }    
                }   
            }
        }
        
        return null;
<<<<<<< HEAD:ckz_POCinvRefresh.cls
    } 
}
=======
    }
    
}
>>>>>>> 56da92c1b8d2be86718d2d57193dd4e2044416ed:ckz_POCinvRefresh.cls
