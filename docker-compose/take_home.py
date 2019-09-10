'''                       
                                                                    

This application won't work! Your challenge is to fix that.

Please connect this application to a persistent database
and encapsulate it in such a way that you can send us a 
zip of the dir and we can have this up and running if we have
the following dependencies installed:

* Docker
* Python
* Flask
* SqlAlchemy

How you do so is entirely up to you. 

HINT: Here at LeafLink we use docker-compose to manage our services 

Deliverable: a zip or otherwise compressed file. This file
MUST include take_home.py and it MUST include a README.MD
that will explain how to run this app so it works. 

HINT: The less we need to type to see that it works, the better :)
'''

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
import os


DBUSER     = os.environ.get('DBUSER') 
DBPASSWORD = os.environ.get('DBPASSWORD') 
DBHOST     = os.environ.get('DBHOST')
DBPORT     = os.environ.get('DBPORT')
DATABASE   = os.environ.get('DATABASE')

DB_URL     = 'mysql+mysqldb://{dbuser}:{dbpassword}@{dbhost}:{dbport}/{database}'.format(dbuser=DBUSER,dbpassword=DBPASSWORD,dbhost=DBHOST,dbport=DBPORT,database=DATABASE)
print(DB_URL)

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] =  DB_URL

app.config['ENV'] = "development"

print('DB URL is: ' + app.config['SQLALCHEMY_DATABASE_URI'])
print('DB Options are: ')
#print ( app.config['SQLALCHEMY_ENGINE_OPTIONS'])
print (app.config) 

db = SQLAlchemy(app)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=False, nullable=False)
    email = db.Column(db.String(120), unique=False, nullable=False)

    def __repr__(self):
        return '<User %r>' % self.username

@app.route("/")
def hello():
    admin = User(username='admin', email='admin@example.com')
    db.session.add(admin)
    db.session.commit()
    return "It works"
try:
  print("creating DB now")

  db.create_all()
  print("DB initialize complete")
except Exception as e:
        print(e)

app.run(host= '0.0.0.0',debug=True) #We have to set the host field, otherwise flask runs internally and not on the IP address of the container -- we do this otherwsie it runs on the localhost 127.0.0.1 address, which maps to inside the container, NOT the host network
