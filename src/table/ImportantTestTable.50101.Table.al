table 50101 "ImportantTestTable"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(2; Message; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Message from the Queue';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure GetNextEntryNo(): Integer
    begin
        if Rec.FindLast() then
            exit(Rec."Entry No." + 1);
        exit(1);
    end;

    procedure DeleteAllRecords()
    begin
        Rec.DeleteAll();
    end;
}