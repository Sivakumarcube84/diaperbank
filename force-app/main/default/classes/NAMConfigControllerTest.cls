@isTest
public class NAMConfigControllerTest {
    @isTest 
    static void construct() {
        NAMConfigController controller = new NAMConfigController();
        controller.changeConfigs();
        Boolean valuePrevious = controller.getDisablePrevious();
        controller.getDisableNext();
        controller.Next();
        controller.Previous();
        String v = controller.version;
        System.assertEquals(valuePrevious, true);
    }

}