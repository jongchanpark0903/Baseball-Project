# Jong Chan Park
# Baseball

# Install and Call packages by using Library function

install.packages("RSQLite")
install.packages("DBI")

library(RSQLite)
library(DBI)
library(reshape2)
library(ggplot2)

# Set Working Directories
setwd("/Users/kjcpark/Downloads")

# Set db
db = dbConnect(SQLite(), "lahman2013.sqlite")

#REF: http://www.seanlahman.com/files/database/readme2013.txt


##### 1. What years does the data cover? are there data for each of these years?
# REF: https://www.w3schools.com/sql/sql_min_max.asp#:~:text=The%20SQL%20MIN()%20and,value%20of%20the%20selected%20column.
# REF: Piazza post #255

# Find the Fields

# Explore what tables we need
dbListTables(db)

# Explore the fields in Teams, Salaries,Table
dbListFields(db, "Teams")
dbListFields(db, "Salaries")
dbListFields(db, "Teams")

countofyearsTeams = dbGetQuery(db, "SELECT yearID, COUNT(*) AS NUM FROM Teams
                               WHERE yearID = (SELECT MIN(yearID) FROM TEAMS)
                               UNION ALL
                               SELECT yearID, COUNT(*) AS NUM FROM Teams
                               WHERE yearID = (SELECT MAX(yearID) FROM TEAMS)")
countofyearsTeams

countofyearsBatting = dbGetQuery(db, "SELECT yearID, COUNT(*) AS NUM FROM Batting
                               WHERE yearID = (SELECT MIN(yearID) FROM Batting)
                               UNION ALL
                               SELECT yearID, COUNT(*) AS NUM FROM Batting
                               WHERE yearID = (SELECT MAX(yearID) FROM Batting)")
countofyearsBatting

countofyearsPitching = dbGetQuery(db, "SELECT yearID, COUNT(*) AS NUM FROM Pitching
                               WHERE yearID = (SELECT MIN(yearID) AS NUM FROM Pitching)
                               UNION ALL
                               SELECT yearID, COUNT(*) AS NUM FROM Pitching
                               WHERE yearID = (SELECT MAX(yearID) FROM Pitching)")
countofyearsPitching


##### 2. How many (unique) people are included in the database? 
#####    How many are players, managers, etc?

### Distinct Player Count
dbListFields(db, "Master")
playernum = dbGetQuery(db,"SELECT COUNT(playerID) AS playerCount FROM Master")
playernum
### Distinct Manager Count
dbListFields(db, "Managers")
managernum = dbGetQuery(db,"SELECT COUNT(DISTINCT playerID) AS managerCount FROM Managers")
managernum
# Inner join on Manager and Player and count how many player became coach. 
duplicatenum = dbGetQuery(db,"SELECT COUNT(DISTINCT Master.playerID) AS Count FROM Managers 
                            INNER JOIN Master ON Managers.playerID = Master.playerID")
duplicatenum

playernum + managernum - duplicatenum


##### 3. How many players became managers?


### Inner join on Manager and Player and group them by plyrMgr so that we can see the difference
becomeManager = dbGetQuery(db,"SELECT COUNT(DISTINCT Master.playerID) AS Count, Managers.plyrMgr 
                           AS plyrMgr FROM Managers INNER JOIN Master ON 
                           Managers.playerID = master.playerID GROUP by Managers.plyrMgr")
becomeManager

# REF: https://rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf

ggplot(becomeManager,aes(plyrMgr,Count, fill = plyrMgr)) + geom_bar(stat = "identity") + 
  labs(title ="How many players became managers?", x = "PlayerManager", y = "Numbers")

##### 4. How many players are there in each year, from 2000 to 2013? 
#####   Do all teams have the same number of players?

playercount= dbGetQuery(db, "SELECT yearID AS Year, 
                        COUNT(DISTINCT playerID) AS Count, 
                        teamID AS Team 
                        FROM Appearances 
                        GROUP by yearID, teamID 
                        Having yearID > 2000")
playercount

ggplot(playercount, aes(Year, Count, fill = Team)) + geom_bar(stat = "identity") + 
  labs(title =" How many players are there in each year, from 2000 to 2013?", 
       x = "Year", y = "Number of players")

ggplot(playercount, aes(Year, Count)) + geom_point() +
  labs(title ="Do all teams have the same number of players?", 
       x = "Year", y = "Number of players")


##### 5. What team won the World Series in 2010? 
#####   Include the name of the team, the league and division.

WSwinner2010 = dbGetQuery(db, "SELECT TeamID, name, lgID, divID 
               FROM Teams 
               WHERE yearID = 2010 
               AND WSWin = 'Y' ")

WSwinner2010
dbListTables(db)
a = dbGetQuery(db, "SELECT * FROM SeriesPost")

##### 6. What team lost the World Series each year? 
#####   Again, include the name of the team, league and division

WSlosers = dbGetQuery(db, "SELECT yearID,teamID, name, lgID, divID 
                     FROM Teams WHERE Lgwin = 'Y'
                     AND WSWin = 'N' ")
WSlosers


##### 7. Compute the table of World Series winners for all years, 
#####    again with the name of the team, league and division.

WSwinners = dbGetQuery(db, "SELECT yearID,teamID, name, lgID, divID 
                     FROM Teams WHERE WSWin = 'Y' ")
WSwinners

##### 8. Compute the table that has both the winner and runner-up for the World Series in 
#####    each tuple/row for all years, again with the name of the team, league and division, 
#####   and also the number games the losing team won in the series.

# REF = https://www.dofactory.com/sql/subquery

#2013|BOS|Boston Red Sox|AL|E|SLN|St. Louis Cardinals|NL|C|3
#2012|SFN|San Francisco Giants|NL|W|DET|Detroit Tigers|AL|C|0
#2011|SLN|St. Louis Cardinals|NL|C|TEX|Texas Rangers|AL|W|3

WSWinnerandLoser = dbGetQuery(db,"SELECT S.yearID Year, S.teamIDwinner,
(SELECT name FROM Teams T WHERE S.teamIDwinner = T.teamID AND S.yearID = yearID) AS winnername,
S.lgIDwinner,
(SELECT divID FROM Teams T WHERE S.teamIDwinner = T.teamID AND S.yearID = yearID) AS winnerlg,
S.teamIDloser, 
(SELECT name FROM Teams T WHERE S.teamIDloser = T.teamID AND S.yearID = yearID) AS losername,
S.lgIDloser, 
(SELECT divID FROM Teams T WHERE S.teamIDloser = T.teamID AND S.yearID = yearID) AS loserlg,
S.losses AS loserwins FROM SeriesPost S WHERE S.round = 'WS' ORDER BY Year DESC")
head(WSWinnerandLoser)

##### 9. Do you see a relationship between the number of games won in a season and 
#####    winning the World Series?

WSwinnergameswon = dbGetQuery(db,"SELECT yearID AS Year, 
                              W*100/G AS Percent FROM Teams WHERE WSWin = 'Y'")
WSwinnergameswon


ggplot(WSwinnergameswon, aes(Year, Percent)) + geom_jitter() + geom_smooth() +
  ggtitle("The winning percentage of WS winner by Years")
  labs(x = "Year", y = "Percent")
  

##### 10. In 2003, what were the three highest salaries? (We refer here to unique salaries, 
#####     i.e., there maybe several players getting the exact same amount.) 
#####     Find the players who got any of these 3 salaries with all of their details?

options(scipen=999)
dbGetQuery(db, "SELECT MAX(salary) FROM Salaries WHERE yearID =2003") # HIGHEST = 22000000

dbGetQuery(db, "SELECT MAX(salary) FROM Salaries 
           WHERE yearID = 2003 AND salary <22000000") #SECOND HIGHEST = 20000000

dbGetQuery(db, "SELECT MAX(salary) FROM Salaries 
           WHERE yearID = 2003 AND salary <20000000") #THIRD HIGHEST = 18700000

top3salary2003 = dbGetQuery(db, "SELECT S.yearID, S.teamID, S.playerID, 
                S.salary, M.nameFirst, M.nameLast, F.POS
                FROM Salaries S INNER JOIN Master M INNER JOIN Fielding F
                ON S.playerID = M.playerID
                AND S.playerID = F.playerID
                AND S.yearID = F.yearID
                WHERE S.yearID = 2003
                AND salary IN(22000000, 20000000,18700000)
                GROUP BY S.playerID
                ORDER BY salary DESC")


##### 11. For 2010, compute the total payroll of each of the different teams. 
#####     Next compute the team payrolls for all years in the database for 
#####     which we have salary information. Display these in a plot.

sumofsalary2010 = dbGetQuery(db, "SELECT teamID AS Teams, Sum(salary) AS sum FROM Salaries
           WHERE yearID = '2010'
           GROUP BY teamID")
sumofsalary2010

ggplot(sumofsalary2010, aes(Teams, sum)) + geom_bar(stat = "identity", aes(fill = Teams)) + 
  coord_flip() + ggtitle("Sum of Salary for each Team in 2010") +
  labs(x = "Teams", y = "Sum of Salaries")


sumofsalary = dbGetQuery(db, "SELECT yearID AS Year, teamID AS Teams, Sum(salary) AS sum 
               FROM Salaries 
               GROUP BY teamID, yearID")
sumofsalary

ggplot(sumofsalary, aes(Teams, sum, fill = Year)) + geom_bar(stat = "identity") + 
  coord_flip()


##### 12. Explore the change in salary over time. Use a plot. 
#####     Identify the teams that won the world series or league on the plot. 
#####     How does salary relate to winning the league and/or world series.

# Average salary over year
averageSalary = dbGetQuery(db, "SELECT S.yearID AS Year, 
                           ROUND(SUM(S.salary)/COUNT(S.yearID)) AS AverageSal,
                           T.wswin FROM Salaries S LEFT JOIN Teams T 
                           ON S.yearID = T.yearID AND T.teamID = S.teamID 
                           WHERE T.wswin = 'N'
                           GROUP BY S.yearID")
averageSalaryofWS = dbGetQuery(db, "SELECT S.yearID AS Year, 
                               ROUND(SUM(S.salary)/COUNT(S.yearID)) AS AverageSal,
                               T.wswin FROM Salaries S LEFT JOIN Teams T 
                               ON S.yearID = T.yearID AND T.teamID = S.teamID 
                               WHERE T.wswin = 'Y'
                               GROUP BY S.yearID")
combined = rbind(averageSalary,averageSalaryofWS)

ggplot(combined,aes(Year,AverageSal)) + geom_bar(stat = "identity", position = "dodge", 
                                                   aes(fill= WSWin)) +
  ggtitle("Average Salary of WS winner and other teams by Year") +
  labs(x = "Year", y = "Average Salary")



### 13. Which player has hit the most home runs? Show the number per year.
Homerun = dbGetQuery(db,"SELECT MAX(B.HR) MaxHR, B.yearID as Year, 
                     B.playerID, M.nameFirst, M.nameLast
                     FROM Batting B INNER JOIN Master M 
                     ON B.playerID = M.playerID 
                     GROUP BY yearID")
Homerun

ggplot(Homerun,aes(Year,MaxHR)) + geom_point() + geom_smooth() +
  ggtitle("Number of Maximum Homerun per Year") +
    labs(x = "Year", y = "Maximum HR")



##### 14. Has the distribution of home runs for players increased over the years?

HomerunDistribution = dbGetQuery(db,"SELECT yearID AS Year, 
                                 SUM(HR)*100/(CAST(SUM(AB) AS REAL)) AS HRPercentage
                                 FROM Batting GROUP BY yearID")
HomerunDistribution

ggplot(HomerunDistribution,aes(Year,HRPercentage)) + geom_point() + geom_smooth() +
  ggtitle("Number of Maximum Homerun per Year") +
  labs(x = "Year", y = "HR Percentage")


##### 15. Do players who hit more home runs receive higher salaries?
HRandSalary = dbGetQuery(db,"SELECT S.playerID, S.yearID as Year, AVG(S.Salary) As AVGsal, 
                          AVG(B.HR) AS AVGHR
                          FROM Salaries S INNER JOIN Batting B
                          ON S.playerID = B.playerID
                          AND S.yearID = B.yearID
                          WHERE B.HR > 3
                          GROUP BY S.playerID" )
HRandSalary

ggplot(HRandSalary,aes(AVGHR,AVGsal, color = Year)) + geom_point() + geom_smooth(color = "Red") +
  ggtitle("Relationship between Average HR and Salary") +
  labs(x = "Average HR", y = "Average Salary")



##### 16. What’s the distribution of Runs and Hits?
HitsDistribution = dbGetQuery(db,"SELECT yearID AS Year, 
                                 (SUM(H)*100)/SUM(AB) AS Percentage,
                                 'Hits' AS Type
                                 FROM Batting GROUP BY yearID")

RunsDistribution = dbGetQuery(db, "SELECT yearID AS Year,
                                 (SUM(R)*100)/SUM(AB) AS Percentage,
                                 'Runs' AS Type
                                 FROM Batting GROUP BY yearID")
HitsandRunsDistribution = rbind(HitsDistribution,RunsDistribution)

ggplot(HitsandRunsDistribution,aes(Year,Percentage, color = Type)) + geom_path(stat = "identity") +
  ggtitle("Percentage of Hits and Runs") +
  labs(x = "Year", y = "Percentage")



###### 17. How are wins related to hits, strikeouts, walks, homeruns and earned runs?
# REF: http://www.sthda.com/english/articles/40-regression-analysis/168-multiple-linear-regression-in-r/#:~:text=Multiple%20linear%20regression%20is%20an,distinct%20predictor%20variables%20(x).&text=The%20%E2%80%9Cb%E2%80%9D%20values%20are%20called,predictor%20variable%20and%20the%20outcome.

Winrelation = dbGetQuery(db, "SELECT (W*100)/G AS WinPercentage, H AS Hits, HR AS Homeruns, BB AS Walks, 
                         SO AS StrikeOut, ER AS EarnedRun FROM Teams ") 
Winrelation

model = lm(WinPercentage ~ Hits + Homeruns + Walks + StrikeOut + EarnedRun, data = Winrelation)
summary(model)


##### 18. What players have pitched in the World Seiries and also hit a home run in their career
HRWSPitcher = dbGetQuery(db, "SELECT P.playerID, SUM(W) AS WSTotalwins, 
                       SUM(B.HR) AS HRcareer, M.nameFirst, M.nameLast 
                       FROM PitchingPost P 
                       INNER JOIN Batting B INNER JOIN Master M 
                       ON P.playerID = B.playerID 
                       AND P.playerID = M.playerID
                       WHERE B.HR > 0
                       AND round = 'WS'
                       GROUP BY P.playerID
                       Order by HRcareer DESC")
HRWSPitcher



