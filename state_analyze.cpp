#include <map>
#include <list>
#include <string>
#include <iostream>
#include <fstream>
#include <boost/foreach.hpp>

typedef std::map<unsigned int, unsigned long int> database;

void open_db(const std::string& db_name, database& db);
void save_db(const std::string& db_name, database& db);
void update_db(database& day, database& month);
void extract_daily_data(const std::string& date_file, const std::string& count_file, database& db);


int main(int argc, char *argv[]) {

  std::string base_dir="/home/ws327/public_html/lowrisc_stat/";

  std::string clone_day_file = base_dir+"clone_day.txt";
  std::string clone_month_file = base_dir+"clone_month.txt";
  std::string view_day_file = base_dir+"view_day.txt";
  std::string view_month_file = base_dir+"view_month.txt";

  std::string clone_date_log_file = base_dir+"clone_date.log";
  std::string clone_count_log_file = base_dir+"clone_count.log";
  std::string view_date_log_file = base_dir+"view_date.log";
  std::string view_count_log_file = base_dir+"view_count.log";


  std::map<unsigned int, unsigned long int> clone_day;
  std::map<unsigned int, unsigned long int> clone_month;
  std::map<unsigned int, unsigned long int> view_day;
  std::map<unsigned int, unsigned long int> view_month;

  open_db(clone_day_file, clone_day);
  open_db(clone_month_file, clone_month);
  open_db(view_day_file, view_day);
  open_db(view_month_file, view_month);

  extract_daily_data(clone_date_log_file, clone_count_log_file, clone_day);
  extract_daily_data(view_date_log_file, view_count_log_file, view_day);

  update_db(clone_day, clone_month);
  update_db(view_day, view_month);

  save_db(clone_day_file, clone_day);
  save_db(clone_month_file, clone_month);
  save_db(view_day_file, view_day);
  save_db(view_month_file, view_month);

}

void extract_daily_data(const std::string& date_file, const std::string& count_file, database& db) {
  std::ifstream date(date_file);
  std::ifstream count(count_file);

  unsigned int day;
  unsigned long int c;
  std::list<unsigned int> date_list;

  while(date >> day) {
    date_list.push_back(day);
  }

  count >> c;
  while(count >> c) {
    db[date_list.front()] = c;
    date_list.pop_front();
  }

  date.close();
  count.close();

}

void save_db(const std::string& db_name, database& db) {
  std::ofstream db_file(db_name);
  BOOST_FOREACH(database::value_type &r, db)
    db_file << r.first << " " << r.second << std::endl;
  db_file.close();
}

void open_db(const std::string& db_name, database& db) {
  std::ifstream db_file(db_name);
  unsigned int t;
  unsigned long int d;
  while(db_file >> t >> d)
    db[t] = d;
  db_file.close();
}

void update_db(database& day, database& month) {
  if(day.size() > 40) {
    unsigned int month_2 = (day.begin()->first)/100;
    unsigned int month_1 = 0;       // the second older month
    unsigned int month_0 = 0;
    unsigned long int count_2 = 0;
    unsigned long int count_1 = 0;
    std::list<unsigned int> old_days;
    for(database::iterator it=day.begin(); it != day.end(); ++it) {
      if((it->first/100)==month_2) {
        old_days.push_back(it->first);
        count_2 += it->second;
      } else {
        if(month_1 == 0)
          month_1 = it->first/100;

        if((it->first/100)==month_1) {
          count_1 += it->second;
        } else {
          month_0 = it->first/100;
          break;
        }
      }
    }

    if(month_0 != 0) {
      BOOST_FOREACH(unsigned int& d, old_days)
        day.erase(d);
      month[month_2] = count_2;
      month[month_1] = count_1;
    } else {
      month[month_2] = count_2;      
    }
  }
}
