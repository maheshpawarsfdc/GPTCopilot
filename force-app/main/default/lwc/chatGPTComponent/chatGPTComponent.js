import { LightningElement } from 'lwc';
import processQuery from '@salesforce/apex/GPTIntegrationController.processQuery';

export default class ChatGPTComponent extends LightningElement {
    userQuery = '';
    response = '';
    isLoading = false;  // Spinner to indicate loading

    // Handle query input changes
    handleQueryChange(event) {
        this.userQuery = event.target.value;
    }

    // Handle query submission
    handleQuerySubmit() {
        if (this.userQuery.trim() === '') {
            this.response = 'Please enter a valid query.';
            return;
        }

        this.isLoading = true;  // Show spinner
        this.response = '';  // Clear previous response

        processQuery({ userQuery: this.userQuery })
            .then(result => {
                this.response = result;  // Update the reactive field 'response'
            })
            .catch(error => {
                console.error('Error during query submission:', error);
                this.response = 'Error occurred while processing the query.';
            })
            .finally(() => {
                this.isLoading = false;  // Hide spinner
                this.userQuery = '';  // Clear input field after submission
            });
    }
}
