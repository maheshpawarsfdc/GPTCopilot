import { LightningElement } from 'lwc';
import processQuery from '@salesforce/apex/GPTIntegrationController.processQuery';

export default class ChatGPTComponent extends LightningElement {
    userQuery = '';
    response = '';  // This is the response that will be shown on the UI

    // Handle query input changes
    handleQueryChange(event) {
        this.userQuery = event.target.value;
        console.log('User Query updated: ' + this.userQuery); // Debugging statement
    }

    // Handle query submission
    handleQuerySubmit() {
        console.log('Submitting query: ' + this.userQuery); // Debug before submission
        
        processQuery({ userQuery: this.userQuery })
            .then(result => {
                console.log('Received response: ' + result); // Debugging statement to check response
                this.response = result;  // Update the reactive field 'response'
            })
            .catch(error => {
                console.error('Error during query submission: ' + JSON.stringify(error)); // Debug error
                this.response = 'Error occurred while processing the query.';
            });
    }
}