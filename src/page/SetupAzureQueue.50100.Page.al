page 84753 "SetupAzureQueue"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Setup Azure Store Queue Service';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = AzureQueuesSetup;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                Caption = 'Setup';
                field(EndPoint; Rec.ConnectionSting)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End point for the Azure Queue Service';
                }
                field(AuthToken; Rec.AuthToken)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Auth Token for the Azure Queue Service';
                    ExtendedDatatype = Masked;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Process;
                trigger OnAction()
                begin
                    if Rec.TestConnection() then
                        Message('Connection is working');
                end;
            }
            action(TestAPI)
            {
                Caption = 'Test Azure Storage API';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = All;
                trigger OnAction()
                var
                    AzureStorageQueuesSdk: Codeunit AzureStorageQueuesSdk;
                    MessageBody: Text;
                    MessageId: Text;
                begin
                    MessageBody := AzureStorageQueuesSdk.GetNextMessageFromQueue('salesorders');
                    MessageId := AzureStorageQueuesSdk.GetMessageIdFromXmlText(MessageBody);
                    Message(MessageId);
                end;
            }
        }

    }

    trigger OnOpenPage()
    begin
        Rec.Reset;
        if not Rec.Get then begin
            Rec.Init;
            Rec.Insert;
        end;
    end;
}