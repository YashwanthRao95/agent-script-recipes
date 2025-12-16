@IsTest
private class ExperienceControllerTest {
    @TestSetup
    static void setupTestData() {
        Contact testContact = new Contact(
            FirstName = 'Alexander',
            LastName = 'Reed',
            Email = 'alex.reed@example.com'
        );

        insert testContact;

        ASR_Customer_Interest__c testInterest = new ASR_Customer_Interest__c(
            Contact__c = testContact.Id,
            Interest_Type__c = 'Dining & Social'
        );

        insert testInterest;

        ASR_Experience__c testExperience = new ASR_Experience__c(
            Name = 'Dinner with friends',
            Duration_Hours__c = 2,
            Start_Time__c = Time.newInstance(17, 30, 0, 0),
            Type__c = 'Dining & Social'
        );

        insert testExperience;
    }

    @IsTest
    static void testGetExperiencesSuccess() {
        // Get test data
        Contact testContact = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        // Start test execution context
        Test.startTest();
        List<ASR_Experience__c> experiences = ExperienceController.getExperiences(
            testContact.Id
        );
        Test.stopTest();

        // Verify response
        Assert.areEqual(1, experiences.size());
        Assert.areEqual('Dinner with friends', experiences[0].Name);
    }
}
