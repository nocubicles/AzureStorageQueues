table 50100 "AzureQueuesSetup"
{
    Caption = 'Azure Queues Setup';
    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary Key';
        }
        field(2; AuthToken; Text[255])
        {
            Caption = 'Auth token';
        }
        field(3; EndPoint; Text[100])
        {
            Caption = 'End Point For Service';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure TestConnection(): Boolean
    var
        AzureQueuesSDK: Codeunit AzureStorageQueuesSdk;
        WarningConnectionNotEstablished: Label 'Please check endpoint and credentials. Unable to establish connection with Azure Queue Service';
    begin
        if not AzureQueuesSDK.TestConnection() then begin
            Message(WarningConnectionNotEstablished);
            exit(false);
        end;
        exit(true);
    end;
}