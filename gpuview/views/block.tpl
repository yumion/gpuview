<div class="col-xl-3 col-md-4 col-sm-6 mb-3 card-block {{gpustat['hostname']}}"
    style="display:{{ 'none' if not gpustat.get('display') else 'grid'}}">
    <div class="card text-white {{ gpu.get('flag', '') }} o-hidden h-100"
        id="{{gpustat.get('hostname')}}_GPU{{gpu.get('index')}}" onclick="openModal(this)">
        <div class="card-header text-white clearfix z-1">
            <span class="float-left">
                <i class="fa fa-user" aria-hidden="true"></i>
            </span>|
            <span class="float-right">
                <i class="fa fa-calendar" aria-hidden="true"></i>
            </span>
        </div>
        <div class="card-body">
            <div class="float-left">
                <div class="card-body-icon">
                    <i class="fa fa-server"></i>
                    <b>
                        {{ gpustat.get('hostname', '-') }}
                        [{{ gpu.get('index', '') }}]
                    </b>
                </div>
                <div>
                    <span class="float-left">
                        <span class="text-nowrap">
                            <i class="fa fa-thermometer-three-quarters" aria-hidden="true"></i>
                            Temp. {{ gpu.get('temperature.gpu', '-') }}&#8451;
                        </span>|
                        <span class="text-nowrap">
                            <i class="fa fa-microchip" aria-hidden="true"></i>
                            Mem. {{ gpu.get('memory', '-') }}%
                        </span>|
                        <span class="text-nowrap">
                            <i class="fa fa-cogs" aria-hidden="true"></i>
                            Util. {{ gpu.get('utilization.gpu', '-') }}%
                        </span>
                    </span>
                </div>
            </div>
        </div>
        <div class="card-footer text-white clearfix small z-1">
            <span class="float-left">
                <i class="fa fa-users" aria-hidden="true"></i>
                {{ gpu.get('users', '-') }} |
                {{ gpu.get('user_processes', '-').replace('(python,','(').replace('(Xorg,','(') }}
            </span>
        </div>
    </div>
</div>
