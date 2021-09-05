


use DATA607;




/* 
	Create 3 tables :
 		movies	:	movie id, movie title, imdb rating and lead actor
	        people :	person id, person name
                ratings : 	movie id, person id, rating

*/



DROP TABLE IF EXISTS movies;


CREATE TABLE movies (
id				int primary key,
name			varchar(40),
imdb_rating		float,
lead_actor		varchar(40)
);



create unique INDEX movies_i0 on movies(id);


DROP TABLE IF EXISTS people;

CREATE TABLE people (
id			int primary key,
name			varchar(40)
);

create unique INDEX people_i0 on people(id);


DROP TABLE IF EXISTS ratings;

CREATE TABLE ratings (
people_id		int,
movie_id		int,
rating			integer CONSTRAINT ratings CHECK (rating is null or (rating > 0 and rating < 6)) null         
);

create unique INDEX ratings_i0 on ratings(people_id, movie_id);






/*
	Note: you can only upload from a secure location stored in @@GLOBAL.secure_file_priv
    This wont work, the infile has to be a literal
		set @dest = concat(@@GLOBAL.secure_file_priv, "\607_Movies.csv");
*/





/* ------------------   Load Movies  --------------------------------- */

delete from movies;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\607_Movies.csv'
INTO TABLE movies
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



/* ------------------   Load People  --------------------------------- */

delete from people;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\607_People.csv'
INTO TABLE people
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



/* ------------------   Load Ratings  --------------------------------- */

delete from ratings;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\607_Ratings.csv'
INTO TABLE ratings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(people_id, movie_id, @vrating)
SET rating = nullif(rtrim(@vrating),'' or " ");