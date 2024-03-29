import pandas as pd
import glob, os, re

CONDITION = "NG" # NG or YG
CODE_GROUP = "SD" # SD or K_ or RP
NAME_GROUP = "Stargardt" # Stargardt or Controls or RetinitisPigmentosa
csv_files = []

csv_files = []
sbj_path = f"../../../ViscachaBehav/group - {NAME_GROUP}/retpigm{CODE_GROUP}0*/*0*{CONDITION}/shape*/*.csv"

for file in glob.glob(sbj_path):
    subject = re.search(fr"\bretpigm{CODE_GROUP}0(\d+)", file)
    subject = int(subject.group(1).lstrip("0"))
    
    
    filename = file
    file = os.path.basename(filename) # single csv file
    expr = re.search(r"\bshape_(dots|texture)(B|W)(_(C|D|V10_20|V1_2|V5_10)|)", filename)


    db = pd.read_csv(filename, sep='\r\t', engine='python')
    # the raw threshold is on the second-last line
    # select just the thr value and replace comma to dot
    db = db.tail(2)
    thr = db.iat[0,0]
    # the line containing the thr have 6 values separated by semicolumn
    # check that we have such a line
    check = thr.split(";")
    if (len(check) != 5):  # it means there is no threshold value
        thr = "NA"
    else:
        float_thr = float(thr.split(";")[2].replace(",", "."))
        # calculate the thr
        thr = ((100/float_thr)-100)*0.020

    csv_files.append([subject, expr.group(0),thr])

        
df = pd.DataFrame(csv_files)
df = pd.DataFrame(csv_files, columns=["ID", "task", "thr"])
# remove duplicate files and keep the newest one
# remove rows with "NA"
new = df.drop_duplicates(subset=["ID", "task"], keep="last")
new = new.drop(new[new.thr == "NA"].index).astype({"thr": "float"})

# new.to_excel(f"./group - {NAME_GROUP}/{CONDITION.lower()}.xlsx", index=False)
new.to_excel(f"./{CONDITION.lower()}.xlsx", index=False)