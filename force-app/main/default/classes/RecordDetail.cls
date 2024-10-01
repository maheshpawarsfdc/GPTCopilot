public class RecordDetail {
    public String fieldName { get; set; }
    public Object fieldValue { get; set; }

    // Constructor
    public RecordDetail(String fieldName, Object fieldValue) {
        this.fieldName = fieldName;
        this.fieldValue = fieldValue;
    }
}
