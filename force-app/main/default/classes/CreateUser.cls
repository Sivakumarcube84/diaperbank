public class CreateUser {
    @InvocableMethod(label='Create User' description='Create users when called by the flow' category='User')
    public static void createNewUser(List<List<User>> record){
        system.debug('Records: '+ record);
        Map<String, String> recordMap = new Map<String, String>();
        recordMap.put('Alias', record[0][0].Alias);
        recordMap.put('UserName', record[0][0].UserName);
        recordMap.put('Firstname', record[0][0].firstName);
        recordMap.put('LastName', record[0][0].LastName);
        recordMap.put('Email', record[0][0].Email);
        recordMap.put('EmailEncodingKey', record[0][0].EmailEncodingKey);
        recordMap.put('TimeZoneSidKey', record[0][0].TimeZoneSidKey);
        recordMap.put('LocaleSidKey', record[0][0].LocaleSidKey);
        recordMap.put('LanguageLocaleKey', record[0][0].LanguageLocaleKey);
         recordMap.put('ContactId', record[0][0].ContactId);
        recordMap.put('ProfileId', record[0][0].ProfileId);
        recordMap.put('IsActive', String.ValueOf(record[0][0].IsActive));
        recordMap.put('Id', record[0][0].Id);
        upsertUsers(recordMap);

    }
     @future
    public static void upsertUsers(Map<String,String> users){
        User u = new User ();
        For(String s : users.keyset()){
            if(s == 'IsActive'){
                 u.Put(s, Boolean.valueOf(users.get(s)));
            } else{
                 u.Put(s, users.get(s));
            }
           
        }
        If(u.id != null){
            u.IsActive = false;
            update u;
        } else {
            insert u;
        }
    }
}