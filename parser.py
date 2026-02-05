import csv
import argparse
import sys
import re

# Define params count in log file
COLS_COUNT = 20

def parse_logs(input_file, output_file, filters=None, sort_field=None):
    logs = []
    # Prepare list of param names for dynamic calculation
    fieldnames = [f"p{i+1}" for i in range(COLS_COUNT)]
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                
                # Split lire, separating by spaces, square braces and doublequotes
                parts = re.findall(r'\[.*?\]|"(?:\\"|[^"])*"|\S+', line)
                if not parts: continue
                
                # Create data map, if there ara less params append with '-', if more - skip them
                row_data = {f"p{i+1}": (parts[i].strip('"[]') if i < len(parts) else "-") for i in range(COLS_COUNT)}
                
                # Dynamic filtering
                keep_row = True
                if filters:
                    for f_key, f_val in filters.items():
                        if f_val and f_val.lower() not in row_data.get(f_key, "").lower():
                            keep_row = False
                            break
                
                if keep_row:
                    logs.append(row_data)

        # Sorting
        if sort_field and logs:
            def sort_key(x):
                val = x.get(sort_field, "")
                if val.replace('.','',1).isdigit(): return float(val)
                return val.lower()
            logs.sort(key=sort_key)

        # Export as CSV
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(logs)
            
    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        sys.exit(3)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=f"Universal Log Parser ({COLS_COUNT} columns)")
    parser.add_argument("input", help="Input log file")
    parser.add_argument("--output", default="logs.csv", help="Output CSV file")
    
    # Create dynamic list for sorting
    parser.add_argument("--sort", choices=[f"p{i+1}" for i in range(COLS_COUNT)], help="Sort by column index")
    
    # Create dynamic list for filtering
    for i in range(1, COLS_COUNT + 1):
        parser.add_argument(f"--f-p{i}", help=f"Filter by column p{i}")
    
    args = parser.parse_args()
    
    # Create a map of chosen filters
    active_filters = {}
    for i in range(1, COLS_COUNT + 1):
        val = getattr(args, f"f_p{i}")
        if val:
            active_filters[f"p{i}"] = val

    parse_logs(args.input, args.output, filters=active_filters, sort_field=args.sort)
    