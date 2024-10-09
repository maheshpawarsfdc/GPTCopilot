import { LightningElement, track } from 'lwc';
import processQuery from '@salesforce/apex/GPTIntegrationController.processQuery';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChatGPTComponent extends LightningElement {
    userQuery = '';
    response = '';
    isLoading = false;  // Spinner to indicate loading
    @track chatHistory = []; // Track chat history

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
                this.addToChatHistory(this.userQuery, this.response); // Add to chat history
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

    // Add the query and response to the chat history
    addToChatHistory(query, response) {
        // Check if the response indicates it's from getRecordDetails
        const isRecordDetailsResponse = response.startsWith('Record Details:');

        if (isRecordDetailsResponse) {
            // Initialize an array to hold formatted responses for each record
            const records = response.split('\n\n'); // Split records by double new lines
            records.forEach(record => {
                const recordFields = [];
                let naturalLanguageResponse = '';

                // Process each line of the record
                const lines = record.trim().split('\n');
                lines.forEach(line => {
                    const parts = line.split(':');
                    if (parts.length === 2) {
                        const fieldName = parts[0].trim();
                        const fieldValue = parts[1].trim();

                        // Build natural language response for each record
                        naturalLanguageResponse += `${fieldName} is ${fieldValue}. `;
                        recordFields.push({
                            name: fieldName,
                            value: fieldValue
                        });
                    }
                });

                // Push individual record details into chat history
                this.chatHistory.push({
                    id: this.chatHistory.length + 1,
                    query: query,
                    responseFields: recordFields,
                    response: naturalLanguageResponse
                });
            });
        } else {
            // If it's not a record details response, use it as is
            this.chatHistory.push({
                id: this.chatHistory.length + 1,
                query: query,
                response: response // Use as natural language response
            });
        }

        // Clear the input field after processing
        this.userQuery = ''; // Clear input
    }

    // Clear chat history
    handleClearChatHistory() {
        this.chatHistory = [];
        this.response = ''; // Optionally clear the last response
        // Show a success message (optional)
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Chat history cleared.',
            variant: 'success'
        }));
    }
}
