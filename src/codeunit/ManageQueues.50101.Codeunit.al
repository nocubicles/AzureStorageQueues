codeunit 50101 "Manage Queues"
{

    procedure ProcessMessagesFromQueue(Queue: Text)
    begin
        if Process(Queue) then begin
            Sleep(2000);
            ProcessMessagesFromQueue(Queue);
        end;
    end;

    local procedure Process(Queue: Text): Boolean
    var
        AzureStorageQueueSdk: Codeunit AzureStorageQueuesSdk;
        MessageBody: Text;
        MessageId: Text;
        MessageText: Text;
        MessagePopreceipt: Text;
        ImportantTestTable: Record ImportantTestTable;
    begin
        MessageBody := AzureStorageQueueSdk.GetNextMessageFromQueue(Queue);
        MessageId := AzureStorageQueueSdk.GetMessageIdFromXmlText(MessageBody);
        MessageText := AzureStorageQueueSdk.GetMessageTextFromXmlText(MessageBody);
        MessagePopreceipt := AzureStorageQueueSdk.GetMessagePopReceiptFromXmlText(MessageBody);

        if (MessageId <> '') AND (MessageText <> '') then begin
            ImportantTestTable.Init();
            ImportantTestTable."Entry No." := ImportantTestTable.GetNextEntryNo();
            ImportantTestTable.Message := MessageText;
            if ImportantTestTable.Insert() then begin
                //important here to check if delete is succesful and then commit. Otherwise we end in loop where messages are reappearing
                if AzureStorageQueueSdk.DeleteMessageFromQueue(Queue, MessageId, MessagePopreceipt) then
                    Commit();
                Process(Queue);
            end;
        end;
        exit(true);
    end;

    procedure GenerateMessagesToQueue(Queue: Text; NumberOfMessages: Integer)
    var
        AzureStorageSdk: Codeunit AzureStorageQueuesSdk;
        Counter: Integer;
    begin
        for Counter := 0 to NumberOfMessages do begin
            AzureStorageSdk.PostMessageToQueue(Queue, 'This is important business data that needs queue: ' + format(Counter))
        end;
    end;
}