@IsTest
public class CreateNewUsersTest {
    @isTest
    public static void createNewUser(){
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        List<User>users =  new List<User>();
        List<List<User>> records = new List<List<User>>();
        User u = new User(firstname = 'ABC',LastName = 'XYZ', 
                          Email = 'testArkus@c64arkus.com',
                          Username = 'testArkusc@64arkus.com258',
                          EmailEncodingKey = 'ISO-8859-1', 
                          Alias = 'tcom', 
                          TimeZoneSidKey = 'America/Los_Angeles', 
                          LocaleSidKey = 'en_US', 
                          LanguageLocaleKey = 'en_US', 
                          ProfileId = pf.Id,
                          IsActive = false
                         ); 
        users.add(u);
        records.add(users);
        insert users;
        List<User> newUser = [SELECT Id, IsActive from User Limit 1];
        records.add(newUser);
        CreateUser.createNewUser(records);
    }
}