drop table comments;
drop table posts;
drop user dbsample;

create user dbsample;

create table posts (
  post_id serial primary key,
  name text not null, 
  title text not null,
  body text not null
);

create table comments (
  comment_id serial primary key,
  post_id int not null references posts(post_id),
  name text not null,
  body text not null
);

grant all on posts to dbsample;
grant all on comments to dbsample; 
grant all on posts_post_id_seq to dbsample;
grant all on comments_comment_id_seq to dbsample;
