import sys

def rewrite_source_file_with_user_define_values(sourcefilename, search_list, replacement_list):
    try:
        with open(sourcefilename, 'r') as file:
            file_data = file.read()
    except FileNotFoundError:
        print(f"Error: File '{sourcefilename}' not found.")
        return

    for i in range(len(search_list)):
        file_data = file_data.replace(search_list[i], replacement_list[i])

    with open(sourcefilename, 'w') as file:
        file.write(file_data)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python script.py <sourcefilename> <search1> <replace1> [<search2> <replace2> ...]")
        sys.exit(1)

    sourcefilename = sys.argv[1]
    search_list = sys.argv[2::2]
    replacement_list = sys.argv[3::2]

    rewrite_source_file_with_user_define_values(sourcefilename, search_list, replacement_list)
