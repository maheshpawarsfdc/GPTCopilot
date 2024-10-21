/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class ChatGPTTestClass {
    @isTest
    static void testProcessQueryWithValidSOQL() {
        // Mock the LLM API response to return a valid SOQL query
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, false));

        // Call the processQuery method with a query that returns a valid SOQL response
        String userQuery = 'Show me all open cases';
        List<Map<String, Object>> result = ChatGPT.processQuery(userQuery);

        // Assert the results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'There should be results for a valid SOQL query');
    }

    @isTest
    static void testProcessQueryWithInvalidSOQL() {
        // Mock the LLM API response to return an invalid SOQL query
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, true));

        // Call the processQuery method with a query that returns an invalid SOQL response
        String userQuery = 'Show me all contacts with invalid SOQL';
        try {
            ChatGPT.processQuery(userQuery);
            System.assert(false, 'An exception should have been thrown for an invalid SOQL query');
        } catch (AuraHandledException e) {
            System.assertEquals('Invalid SOQL query format.', e.getMessage(), 'Expected an invalid SOQL format error');
        }
    }

    @isTest
    static void testProcessQueryWithSOSL() {
        // Mock the LLM API response to return a valid SOSL query
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false, false));

        // Call the processQuery method with a query that returns a valid SOSL response
        String userQuery = 'Find all records containing "John"';
        List<Map<String, Object>> result = ChatGPT.processQuery(userQuery);

        // Assert the results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'There should be results for a valid SOSL query');
    }

    @isTest
    static void testGetResponseFromLLMException() {
        // Mock the LLM API response to simulate an error scenario
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false, true));

        // Call the getResponseFromLLM method and handle the exception
        try {
            ChatGPT.processQuery('Throw an error');
            System.assert(false, 'An exception should have been thrown for an API error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('API Error'), 'Expected an API Error message');
        }
    }

    @isTest
    static void testExecuteSoqlQueryCountQuery() {
        // Test the executeSoqlQuery method with a count query
        String countQuery = 'SELECT COUNT() FROM Account';
        List<Map<String, Object>> result = ChatGPT.executeSoqlQuery(countQuery);

        // Assert that the count result is returned correctly
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result[0].containsKey('count'), 'Result should contain a count key');
    }

    @isTest
    static void testExecuteSoqlQueryWithRecords() {
        // Create test data for the SOQL query
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        // Test the executeSoqlQuery method with a query that returns records
        String soqlQuery = 'SELECT Id, Name FROM Account';
        List<Map<String, Object>> result = ChatGPT.executeSoqlQuery(soqlQuery);

        // Assert the records returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'There should be at least one record returned');
    }

    @isTest
    static void testExecuteSoslQuery() {
        // Create test data for the SOSL query
        Contact testContact = new Contact(LastName='Doe');
        insert testContact;

        // Test the executeSoslQuery method with a valid SOSL query
        String soslQuery = 'FIND \'Doe\' IN ALL FIELDS RETURNING Contact(Id, LastName)';
        List<Map<String, Object>> result = ChatGPT.executeSoslQuery(soslQuery);

        // Assert the results returned
        System.assertNotEquals(null, result, 'Result should not be null');
        
    }

    @isTest
    static void testHandleGeneralQuery() {
        // Test the handleGeneralQuery method
        String generalResponse = 'This is a general response';
        List<Map<String, Object>> result = ChatGPT.handleGeneralQuery(generalResponse);

        // Assert the response is handled correctly
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('General response: This is a general response', result[0].get('response'), 'General response should be returned correctly');
    }
}
