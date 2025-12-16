@IsTest
private class PersonalizedGuestExperiencesTest {
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
    static void testPersonalizedGuestExperiencesSuccess() {
        // Get test contact
        Contact testContact = [
            SELECT Id, Email
            FROM Contact
            LIMIT 1
        ];

        // Create test request
        PersonalizedGuestExperiences.Request request = new PersonalizedGuestExperiences.Request();
        request.email = testContact.email;

        // Start test execution context
        Test.startTest();
        List<PersonalizedGuestExperiences.Response> responses = PersonalizedGuestExperiences.getSessions(
            new List<PersonalizedGuestExperiences.Request>{ request }
        );
        Test.stopTest();

        // Verify response
        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isNotNull(responses[0].Prompt, 'Prompt should not be null');
    }
}
