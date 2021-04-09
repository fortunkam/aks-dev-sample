<template>
  <div class="container">
    <h3> Weather Forecasts:</h3>
    <table class="table">
      <thead>
        <tr>
          <th scope="col">Date</th>
          <th scope="col">Temperature (<sup>o</sup>C)</th>
          <th scope="col">Summary</th>
          <th scope="col">Host</th>
          <th scope="col">DebugField</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="forecast in forecasts" v-bind:key="forecast.date"> 
          <th scope="row">{{forecast.date}}</th>
          <td>{{forecast.temperatureC}}</td>
          <td>{{forecast.summary}}</td>
          <td>{{forecast.host}}</td>
          <td>{{forecast.updateCheck}}</td>
        </tr>
      </tbody>
    </table> 
  </div> 
</template>

<script>
    import axios from 'axios'

    export default {
        name: 'WeatherForecast',
        data() {
            return {
                forecasts: null
            }
        },
        created: function() {
            console.log(process.env);
            axios
                .get(process.env.VUE_APP_WEATHER_API_URL)
                .then(res => {
                    this.forecasts = res.data;
                })
        }
    }
</script>

<style>
    h3 {
        margin-bottom: 5%;
    }
</style>