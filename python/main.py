import pymongo
import csv

# Replace with your MongoDB connection string and database name
MONGO_URI = "mongodb+srv://username:password@mongoUrl/attendance?retryWrites=true&w=majority"
DATABASE_NAME = "attendance"

def export_verified_records():
    client = pymongo.MongoClient(MONGO_URI)
    db = client[DATABASE_NAME]
    
    # List all collection names (skip system collections)
    collections = [name for name in db.list_collection_names() if not name.startswith("system.")]
    
    for collection_name in collections:
        collection = db[collection_name]
        # Query only the records where verified is True
        records_cursor = collection.find({"verified": True})
        
        # Create a CSV file for the collection
        csv_filename = f"{collection_name}.csv"
        with open(csv_filename, mode="w", newline="", encoding="utf-8") as csvfile:
            writer = csv.writer(csvfile)
            # Write CSV header
            writer.writerow(["Reg No.", "verified", "verified at"])
            # Write each record's columns
            for record in records_cursor:
                reg_no = record.get("registrationNo", "")
                verified = record.get("verified", False)
                verified_at = record.get("verifiedAt", "")
                writer.writerow([reg_no, verified, verified_at])
        
        print(f"Created CSV for collection: {collection_name}")

    client.close()
    print("Finished exporting CSV files.")


if __name__ == "__main__":
    export_verified_records()