    <div class="content-wrapper" id="gpu-content">
        <div class="container-fluid" style="padding: 200px 40px 40px 40px">
            <div class="row">
                % for gpustat in gpustats:
                % for gpu in gpustat.get('gpus', []):
                % include('block.tpl')
                % end
                % end
            </div>
            <!--
            <footer class="sticky-footer">
                <div class="container">
                    <div class="text-center text-white">
                        <small><a href='https://github.com/fgaim/gpuview'>gpuview</a> © 2022</small>
                    </div>
                </div>
            </footer>
            -->
        </div>
    </div>