#!/usr/bin/env python
# coding: utf-8



'''
Copyright [2020] [Satyajeet Narayan]
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''

import numpy as np
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split

reg= LinearRegression()

dataset= pd.read_excel("Regression.xlsx", sheet_name="Linear Regression")

    
dataset.head()
dataset.isnull().sum()
dataset.describe()
dataset.corr()

def reg(col_name):

    x=dataset[[col_name]]
    y=dataset[['price']]
    
    x_train,x_test,y_train,y_test= train_test_split(x,y,test_size=0.3,random_state=10)
    

    reg.fit(x_train,y_train)

    prediction= reg.predict(x_test)
    
    RMSE=np.sqrt(mean_squared_error(y_test,prediction))
    r2=r2_score(y_test, prediction)
    
    print("R Sqaure value is", r2)
    print("Root mean square is ", RMSE)
    
    unseen_pred=reg.predict(np.array([[2]]))
    print("The estiamted salary is",unseen_pred)


reg('bedrooms')


'''Note:
Most of the EDA part is not shown as the purpose is only to get the essence of Linear Regression '''

