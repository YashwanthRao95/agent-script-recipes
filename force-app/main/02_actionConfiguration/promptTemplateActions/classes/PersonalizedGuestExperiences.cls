public with sharing class PersonalizedGuestExperiences {
    // Make this method available for grounding
    // the Generate_Personalized_Schedule prompt template
    @InvocableMethod(
        label='Get sessions of interest for today'
        description='Get today\'s sessions that match the user\'s interests.'
    )
    public static List<Response> getSessions(List<Request> requests) {
        String email = requests[0].email;

        // Get contact ID
        Id contactId = [
            SELECT Id
            FROM Contact
            WHERE Email = :email
            WITH USER_MODE
            LIMIT 1
        ]
        .Id;

        // Get experiences for contact
        List<ASR_Experience__c> experiences = ExperienceController.getExperiences(
            contactId
        );

        // Create expected response
        List<Response> responses = new List<Response>();
        Response res = new Response();
        res.prompt = JSON.serialize(experiences);
        responses.add(res);
        return responses;
    }

    // The variables in this class need to match the prompt template inputs,
    // that may be different on each prompt template
    public class Request {
        @InvocableVariable(
            required=true
            description='The guest\'s email address'
        )
        public String email;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}
