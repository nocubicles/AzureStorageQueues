page 50101 "ImportantTestPage"
{
    PageType = List;
    Caption = 'Important Test page for queues';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = ImportantTestTable;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    Caption = 'Message from the queue';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestAPI)
            {
                Caption = 'Empty table';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.DeleteAllRecords();
                end;
            }
            action(PostToQueue)
            {
                Caption = 'Post 100 records to queue';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = All;
                trigger OnAction()
                var
                    ManageQueues: Codeunit "Manage Queues";
                begin
                    ManageQueues.GenerateMessagesToQueue('businessdata', 100);
                end;
            }
            action(ProcessQueue)
            {
                Caption = 'Process queue and create important business data in BC';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = All;
                trigger OnAction()
                var
                    ManageQueues: Codeunit "Manage Queues";
                begin
                    ManageQueues.ProcessMessagesFromQueue('businessdata');
                end;
            }
        }
    }
}