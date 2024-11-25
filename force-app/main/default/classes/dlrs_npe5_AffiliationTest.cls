/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_npe5_AffiliationTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_npe5_AffiliationTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new npe5__Affiliation__c());
    }
}