/**
 * @description Test class for Action Description Overrides Flows
 * Tests all flows used in the action description overrides recipe
 */
@IsTest
private class ActionDescriptionOverridesFlowTest {
    @IsTest
    static void testPerformSearch() {
        // Set input variables for the flow
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('query', 'test search');
        inputs.put('filters', 'status=active');

        // Run the flow
        Test.startTest();
        Flow.Interview.PerformSearch flowInterview = new Flow.Interview.PerformSearch(
            inputs
        );
        flowInterview.start();
        Test.stopTest();

        // Verify the expected outcome
        List<String> results = (List<String>) flowInterview.getVariableValue(
            'results'
        );
        Assert.areNotEqual(null, results, 'Results should be returned');
        Assert.areEqual(1, results.size(), 'Should return at least one result');
    }
}
