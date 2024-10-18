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
        if (this.userQuery.trim() === '') {
            this.showToast('Error', 'Please enter a valid query.', 'error');
            return;
        }

        this.isLoading = true;
        const queryToSend = this.userQuery;

        processQuery({ userQuery: queryToSend })
            .then(result => {
                // If the result is a valid SOQL response, format it nicely
                this.addToChatHistory(queryToSend, JSON.stringify(result));
            })
            .catch(error => {
                console.error('Error during query submission:', error);
                this.showToast('Error', 'Error occurred while processing the query: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
                this.userQuery = '';
            });
    }

    addToChatHistory(query, response) {
        this.chatHistory.push({
            id: this.chatHistory.length + 1,
            query: query,
            response: response
        });
    }

    handleClearChatHistory() {
        this.chatHistory = [];
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
