import { LightningElement, track } from 'lwc';
import processQuery from '@salesforce/apex/ChatGPT.processQuery'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChatbotComponent extends LightningElement {
    userQuery = '';
    isLoading = false;
    @track chatHistory = [];

    handleQueryChange(event) {
        this.userQuery = event.target.value;
    }

    handleQuerySubmit() {
        if (!this.userQuery.trim()) {
            this.showToast('Error', 'Please enter a valid query.', 'error');
            return;
        }

        this.isLoading = true;
        const queryToSend = this.userQuery;

        console.log('User Query:', queryToSend); // Log the user query before processing

        processQuery({ userQuery: queryToSend })
            .then(result => {
                console.log('Apex Method Result:', result); // Log the result from the Apex method

                if (!result || result.length === 0) {
                    console.error('No data returned from Apex processQuery method'); // Log if no data is returned
                    this.showToast('Error', 'No data returned from the server.', 'error');
                    return;
                }

                const formattedResponse = this.formatData(result);
                console.log('Formatted Response:', formattedResponse); // Log the formatted response
                this.addToChatHistory(queryToSend, formattedResponse);
            })
            .catch(error => {
                console.error('Error processing the query:', error); // Log the error message
                this.showToast('Error', 'Error processing the query: ' + error.body.message, 'error');
            })
            .finally(() => {
                console.log('Finished processing query'); // Log when the processing is complete
                this.isLoading = false;
                this.userQuery = '';
            });
    }

    formatData(queryResults) {
        if (!queryResults || queryResults.length === 0) {
            return 'No records found.';
        }
    
        return queryResults.map(record => {
            return Object.keys(record).map(fieldName => {
                const fieldValue = record[fieldName];
                return `${fieldName}: ${fieldValue != null ? fieldValue : 'N/A'}`;
            }).join(', ');
        }).join('\n\n');
    }

    addToChatHistory(query, response) {
        console.log('Adding to Chat History:', { query, response }); // Log the new chat history entry
        this.chatHistory = [...this.chatHistory, {
            id: this.chatHistory.length + 1,
            query: query,
            response: response
        }];
    }

    handleClearChatHistory() {
        this.chatHistory = [];
        console.log('Chat history cleared'); // Log when chat history is cleared
        this.showToast('Success', 'Chat history cleared.', 'success');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}
