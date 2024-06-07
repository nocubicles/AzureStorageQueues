codeunit 84752 "AzureStorageQueuesSdk"
{
    trigger OnRun()
    begin

    end;

    procedure PostMessageToQueue(Queue: Text; MessageBody: Text): Boolean
    var
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
    begin
        SetupHttpClient();
        if EnsureQueueExists(Queue) then begin
            HttpContent.WriteFrom('<QueueMessage><MessageText>' + MessageBody + '</MessageText></QueueMessage>');
            HttpClient.Post(ConstructRequestUriForMessages(Queue), HttpContent, HttpResponse);
            if not (HttpResponse.IsSuccessStatusCode) then begin
                HttpResponse.Content().ReadAs(ResponseText);
                Error(ResponseText);
            end;
            exit(HttpResponse.IsSuccessStatusCode);
        end;
    end;

    procedure GetMessageIdFromXmlText(var Document: text): Text[50]
    var
        MessageDocument: XmlDocument;
        MessageId: XmlNode;
    begin
        if XmlDocument.ReadFrom(Document, MessageDocument) then begin
            if MessageDocument.SelectSingleNode('QueueMessagesList/QueueMessage/MessageId', MessageId) then begin
                exit(MessageId.AsXmlElement().InnerText())
            end;
        end;
    end;

    procedure GetMessagePopReceiptFromXmlText(var Document: Text): text[30]
    var
        MessageDocument: XmlDocument;
        PopReceipt: XmlNode;
    begin
        if XmlDocument.ReadFrom(Document, MessageDocument) then begin
            if MessageDocument.SelectSingleNode('QueueMessagesList/QueueMessage/PopReceipt', PopReceipt) then begin
                exit(PopReceipt.AsXmlElement().InnerText())
            end;
        end;
    end;

    procedure GetMessageTextFromXmlText(var Document: Text): Text
    var
        MessageDocument: XmlDocument;
        MessageText: XmlNode;
    begin
        if XmlDocument.ReadFrom(Document, MessageDocument) then begin
            if MessageDocument.SelectSingleNode('QueueMessagesList/QueueMessage/MessageText', MessageText) then begin
                exit(MessageText.AsXmlElement().InnerText())
            end;
        end;
    end;

    procedure GetNextMessageFromQueue(Queue: Text): Text
    var
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
    begin
        SetupHttpClient();
        if EnsureQueueExists(Queue) then begin
            HttpClient.Get(ConstructRequestUriForMessages(Queue), HttpResponse);
        end;
        HttpResponse.Content().ReadAs(ResponseText);

        if HttpResponse.IsSuccessStatusCode then begin
            Exit(ResponseText);
        end else
            Error(ResponseText);
    end;

    procedure DeleteMessageFromQueue(Queue: Text; MessageID: Text[100]; Popreceipt: Text[30]): Boolean
    var
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
    begin
        SetupHttpClient();
        HttpClient.Delete(ConstructRequestUriForMessage(Queue, MessageID, Popreceipt), HttpResponse);
        exit(HttpResponse.IsSuccessStatusCode);
    end;


    procedure TestConnection(): Boolean
    var
        HttpResponseMessage: HttpResponseMessage;
    begin
        SetupHttpClient();
        HttpClient.Get(ConstructRequestUriForAccount() + '&restype=service&comp=properties', HttpResponseMessage);
        exit(HttpResponseMessage.IsSuccessStatusCode);
    end;

    procedure ListQueues(): Text
    var
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
    begin
        SetupHttpClient();
        HttpClient.Get(ConstructRequestUriForAccount() + '&comp=list', HttpResponseMessage);
        if HttpResponseMessage.IsSuccessStatusCode then begin
            if HttpResponseMessage.Content.ReadAs(ResponseText) then
                exit(ResponseText);
        end;
    end;

    procedure EnsureQueueExists(Queue: Text): Boolean
    var
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        ResponseText: Text;
    begin
        SetupHttpClient();
        HttpClient.Put(ConstructRequestUriForQueue(Queue), HttpContent, HttpResponseMessage);
        if not (HttpResponseMessage.IsSuccessStatusCode) then begin
            HttpResponseMessage.Content().ReadAs(ResponseText);
            Error(ResponseText);
        end;
        exit(HttpResponseMessage.IsSuccessStatusCode);
    end;

    local procedure ConstructRequestUriForQueue(Queue: Text): Text
    var
        AzureQueuesSetup: Record AzureQueuesSetup;
    begin
        if AzureQueuesSetup.Get() then begin
            exit(AzureQueuesSetup.EndPoint + '/' + Queue + '/' + AzureQueuesSetup.AuthToken);
        end;
    end;

    local procedure ConstructRequestUriForAccount(): Text
    var
        AzureQueuesSetup: Record AzureQueuesSetup;
    begin
        if AzureQueuesSetup.Get() then begin
            exit(AzureQueuesSetup.EndPoint + '?' + AzureQueuesSetup.AuthToken);
        end;
    end;

    local procedure ConstructRequestUriForMessage(Queue: Text; MessageID: Text; Popreceipt: Text): Text
    var
        AzureQueuesSetup: Record AzureQueuesSetup;
    begin
        if AzureQueuesSetup.Get() then begin
            exit(AzureQueuesSetup.EndPoint + '/' + Queue + '/' + 'messages' + '/' + MessageID + AzureQueuesSetup.AuthToken + '&' + 'popreceipt=' + Popreceipt);
        end;
    end;

    local procedure ConstructRequestUriForMessages(Queue: Text): Text
    var
        AzureQueuesSetup: Record AzureQueuesSetup;
    begin
        if AzureQueuesSetup.Get() then begin
            exit(AzureQueuesSetup.EndPoint + '/' + Queue + '/' + 'messages' + AzureQueuesSetup.AuthToken);
        end;
    end;

    local procedure SetupHttpClient()
    begin
        HttpClient.Clear();
        HttpClient.DefaultRequestHeaders.Add('x-ms-blob-type', 'blockblob');
    end;

    var
        ErrEndPointMissing: Label 'Please setup Azure Queues endpoint';
        ErrAuthTokenMisisng: Label 'Please setup Azure Queues auth token';
        HttpClient: HttpClient;
}