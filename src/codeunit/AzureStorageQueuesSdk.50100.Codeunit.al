codeunit 84752 "AzureStorageQueuesSdk"
{
    trigger OnRun()
    begin

    end;

    procedure PostMessageToQueue(Queue: Text; MessageBody: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
    begin
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
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
    begin
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
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
    begin
        HttpClient.Delete(ConstructRequestUriForMessage(Queue, MessageID, Popreceipt), HttpResponse);
        exit(HttpResponse.IsSuccessStatusCode);
    end;


    procedure TestConnection(): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
    begin
        HttpClient.Get(ConstructRequestUriForAccount() + '&restype=service&comp=properties', HttpResponseMessage);
        exit(HttpResponseMessage.IsSuccessStatusCode);
    end;

    procedure ListQueues(): Text
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
    begin
        HttpClient.Get(ConstructRequestUriForAccount() + '&comp=list', HttpResponseMessage);
        if HttpResponseMessage.IsSuccessStatusCode then begin
            if HttpResponseMessage.Content.ReadAs(ResponseText) then
                exit(ResponseText);
        end;
    end;

    procedure EnsureQueueExists(Queue: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        ResponseText: Text;
    begin
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
            exit(AzureQueuesSetup.EndPoint + AzureQueuesSetup.AuthToken);
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

    //DoRequestWithComplexAuth is not working yet
    procedure DoRequestWithComplexAuth(Queue: Text)
    var
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
        AuthString: Text;
        AuthSchemeName: Text;
        Signature: Text;
        StringToSign: Text;
        RequestVerb: Text;
        EncryptionManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option SHA256;
        AzureQueuesSetup: Record AzureQueuesSetup;
    begin
        AzureQueuesSetup.Get();
        AzureQueuesSetup.FieldError(EndPoint, ErrEndPointMissing);
        AzureQueuesSetup.FieldError(AuthToken, ErrAuthTokenMisisng);
        HttpHeaders.Add('x-ms-date', format(CurrentDateTime()));
        AuthSchemeName := 'SharedKeyLite';
        RequestVerb := 'PUT';

        StringToSign := RequestVerb + '\n' +
                        '\n' +
                        'text/plain;' + '\n' +
                        'x-ms-date:' + format(CurrentDateTime()) + '\n' +
                        'x-ms-meta-m1:v1' + '\n' +
                        'x-ms-meta-m2:v2' + '\n' +
                        Queue;
        Signature := EncryptionManagement.GenerateHashAsBase64String(StringToSign, HashAlgorithmType::SHA256);

        HttpHeaders.Add('Authorization', Format(AuthSchemeName + ' ' + Queue + ':' + Signature));

        HttpContent.GetHeaders(HttpHeaders);
        HttpRequest.Content := HttpContent;
        HttpRequest.SetRequestUri(AzureQueuesSetup.EndPoint);
        HttpRequest.Method := 'PUT';

        HttpClient.Send(HttpRequest, HttpResponse);

        HttpResponse.Content().ReadAs(ResponseText);

        Message(ResponseText);
    end;

    var
        ErrEndPointMissing: Label 'Please setup Azure Queues endpoint';
        ErrAuthTokenMisisng: Label 'Please setup Azure Queues auth token';
}