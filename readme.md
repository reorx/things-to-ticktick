# Things to TickTick

Export tasks from Things.app to [TickTick](https://ticktick.com/) format.

> **Note about TickTick:** <br>
> TickTick has a special version called Dida365 registered and operated in China mainland,
> which is what I'm using. For what I know the two services have no differences
> in functionality, so the script `things_to_dida.sh` should also work for TickTick,
> if not, please tell me and I'll try to port it as the real `things_to_ticktick.sh`.


## Usage

1\. Export TickTick/Dida365 backup file

```bash
$ ./things_to_dida.sh all > dida-$(date +"%Y%m%d").csv
```

2\. Go to the web app, click import button, and choose the file you just exported.

- Dida365: [设置 > 备份与导入](https://dida365.com/webapp/#settings/backup), [如何在滴答清单中批量导入任务？](https://help.dida365.com/faqs/6194677415654981632/)
- TickTick: [How do I import data into TickTick from other apps?](https://support.ticktick.com/hc/en-us/articles/360012848611-How-do-I-import-data-into-TickTick-from-other-apps-)


## Consistency

### Tasks

In Things.app, task has the following statuses:
- Open
- Completed
- Cancelled

there's an attribute called `trashed` used to determine whether it's deleted or not.

This project only export those tasks that are either **Open** or **Completed**,
and not **trashed** at the same time.

Because migration is more about not losing the content, attributes like due date and
start date are discarded, you can manually add them after importing,
which normally should not cause too much hassle.

Created time and completed time are kept, they are alway very useful.

Tags are kept.

Checklist and it's status are kept. In TickTick checklist is part of the task description,
so I merged checklist with the original description.

### Project and Area

TickTick uses List to organize a group of tasks, so Project and Area in Things are both
converted as List in TickTick. TickTick Folder is not used.

## Debugging

If you are in doubt with the export result, you can use other tools to read
or edit the csv file.

**CLI**:
1. Install [visidata](https://github.com/saulpw/visidata)
2. `./things_to_dida.sh tasks | vd -f csv`

**GUI**: <br>
Recommend [Easy CSV Editor](https://apps.apple.com/us/app/easy-csv-editor/id1171346381)


## Credits

This project is mostly a fork of the `csv` plugin from
[AlexanderWillner/things.sh](https://github.com/AlexanderWillner/things.sh),
I just made it a standalone script and added some subtle tunes to fit
TickTick's backup format.


## References

SQLite:
- [Built-In Scalar SQL Functions](https://www.sqlite.org/lang_corefunc.html) 
- [Window Functions](https://www.sqlite.org/windowfunctions.html) 
- [Date And Time Functions](https://www.sqlite.org/lang_datefunc.html) 
- [Built-in Aggregate Functions](https://www.sqlite.org/lang_aggfunc.html) 
