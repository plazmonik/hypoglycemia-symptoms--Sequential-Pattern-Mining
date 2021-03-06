library(arules)
library(arulesSequences)
library(ggplot2)
library(dplyr)

download.file('http://staff.ii.pw.edu.pl/~gprotazi/dydaktyka/dane/diab_trans.data', destfile = 'data/diab_trans.data')
diab.df <- read.csv("data/diab_trans.data", header=TRUE, stringsAsFactors = FALSE)

head(diab.df)

diab.df$code_id = as.numeric(substring(diab.df$code, 4,5))
description.df <- read.csv('data/description.txt', header=TRUE)

input.df <- inner_join(diab.df,description.df)
head(select(input.df, code_id, description_PL))


to_chunk.df = input.df %>% 
  group_by(code_id) %>%
  distinct(value) %>%
  summarise(count=n()) %>%
  filter(count>1)
to_chunk.df$measure = TRUE 

base.df <- left_join(input.df, to_chunk.df)
dawka = c(33, 34, 35)
base.df <- base.df %>% mutate(type = ifelse(measure==T, ifelse(code_id %in% dawka, 'dawka', 'pomiar'), 'wydarzenie'))
to_chunk_temp.df = inner_join(description.df, to_chunk.df)
as.vector(to_chunk_temp.df$description_PL)



to_hist_pomiar.df <- base.df %>% na.omit() %>% filter(measure==TRUE, type=='pomiar')
ggplot(to_hist_pomiar.df, aes(x=value, fill=description_PL))+geom_histogram()
to_hist_dawka.df <- base.df %>% na.omit() %>% filter(measure==TRUE, type=='dawka')
ggplot(to_hist_dawka.df, aes(x=value, fill=description_PL))+geom_histogram(binwidth = 1)+scale_x_continuous(limits = c(2,40))

to_hist.df <- base.df %>% na.omit() %>% filter(measure==TRUE, code_id==62)

q <- quantile(to_hist.df$value, c(0.20, 0.80))

ggplot(to_hist.df, aes(x=value))+geom_histogram()+geom_vline(xintercept = c(q[1], q[2]))

to_divide.df <- base.df %>% na.omit() %>% filter(measure==TRUE)
for_loop <- to_divide.df %>% distinct(code_id)
qa = c()
qb = c()
code = c()

for(i in for_loop$code_id){
  to_divide_tmp.df <- base.df %>% na.omit() %>% filter(measure==TRUE, code_id==i)
  qa = c(qa,  quantile(to_divide_tmp.df$value, c(0.20)))
  qb = c(qb,  quantile(to_divide_tmp.df$value, c(0.80)))
  code = c(code, i)
  
}
df <- data.frame(code,qa,qb)

cluster <- function(code_id, value){

      qa=df[df$code==code_id,"qa"]
      qb=df[df$code==code_id,"qb"]
      if(length(qa)==0 || length(qb)==0 )
        return(NA)

      if(is.na(value))
        return(NA)
      if(is.null(value))
        return(NA)
      
      if(value<qa){
        return('niski')
        }
      else if(value>qb){
        return('wysoki')
        }
      else if(value>=qa & value<=qb){
        return('normalny')
        }
      else{
        return(NA)}
}

base.df$value.level <- mapply(cluster, base.df$code_id, base.df$value)
df <-base.df %>%
  mutate(description = if_else(!is.na(value.level),paste(description_PL,"poziom", value.level), as.character(description_PL)))  %>%
  select(patient_id, time_sek, description)
new_id <- df %>%arrange(description) %>% distinct(description)
new_id$id <- seq.int(nrow(new_id))
df = inner_join(df, new_id)
View(df)




