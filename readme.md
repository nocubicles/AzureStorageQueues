# This project implements [Azure Storage Queues](https://docs.microsoft.com/en-us/azure/storage/queues/storage-queues-introduction) in Business Central

## How it works?

Create Azure Storage Account and get your endpoint and [Shared access Signature token](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview)

Fill out credentials in 'Setup Azure Store Queue Service'

You are ready to go.

## Why use message queues?

Why use queues at all and not integrated via Odata/Soap etc?

Using message queues gives lots of flexibility. It allows you to process data asynchronously. Maybe you have IoT application that wants to post 10000 messages to Business Central in minute? Use message queues etc.

Theres codeunit `codeunit 50100 "AzureStorageQueuesSdk"` which has following methods:
- PostMessageToQueue
- GetNextMessageFromQueue
- DeleteMessageFromQueue
- TestConnection
- EnsureQueueExists
- GetMessageIdFromXmlText
- GetMessagePopReceiptFromXmlText
- GetMessageTextFromXmlText

Theres also page `'Important Test page for queues'` which allowes to play around with the queues.

Example of how to use the SDK is below. This is probably not good idea to run in production yet but gives a idea how to work with the Azure queues and how to poll messages.

`
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
`